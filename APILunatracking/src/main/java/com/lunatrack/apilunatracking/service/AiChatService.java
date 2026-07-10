package com.lunatrack.apilunatracking.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.lunatrack.apilunatracking.dto.ChatRequest;
import com.lunatrack.apilunatracking.model.CycleEntry;
import com.lunatrack.apilunatracking.model.User;
import com.lunatrack.apilunatracking.repository.CycleEntryRepository;
import com.lunatrack.apilunatracking.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import okhttp3.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AiChatService {

    private final UserRepository userRepository;
    private final CycleEntryRepository cycleEntryRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final OkHttpClient httpClient = new OkHttpClient();

    @Value("${groq.api.key}")
    private String apiKey;

    @Value("${groq.api.url}")
    private String apiUrl;

    @Value("${groq.model}")
    private String model;

    public String chat(String userEmail, ChatRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() ->
                        new UsernameNotFoundException("User not found"));

        String systemPrompt = buildSystemPrompt(
                buildCycleContext(user), user.getName());

        try {
            // Build Groq request (OpenAI format)
            ObjectNode requestBody = objectMapper.createObjectNode();
            requestBody.put("model", model);
            requestBody.put("max_tokens", 1024);
            requestBody.put("temperature", 0.7);

            ArrayNode messages = requestBody.putArray("messages");

            // System message
            ObjectNode sysMsg = messages.addObject();
            sysMsg.put("role", "system");
            sysMsg.put("content", systemPrompt);

            // Conversation history
            if (request.getHistory() != null) {
                for (ChatRequest.ChatMessage msg : request.getHistory()) {
                    ObjectNode msgNode = messages.addObject();
                    msgNode.put("role", msg.getRole());
                    msgNode.put("content", msg.getContent());
                }
            }

            // Current user message
            ObjectNode userMsg = messages.addObject();
            userMsg.put("role", "user");
            userMsg.put("content", request.getMessage());

            // Call Groq API
            RequestBody body = RequestBody.create(
                    objectMapper.writeValueAsString(requestBody),
                    MediaType.get("application/json"));

            Request httpRequest = new Request.Builder()
                    .url(apiUrl)
                    .addHeader("Authorization", "Bearer " + apiKey)
                    .addHeader("Content-Type", "application/json")
                    .post(body)
                    .build();

            try (Response response = httpClient
                    .newCall(httpRequest).execute()) {
                if (!response.isSuccessful()) {
                    return "Xin lỗi, tôi đang gặp sự cố. "
                            + "Vui lòng thử lại sau.";
                }
                String responseBody = response.body().string();
                JsonNode json = objectMapper.readTree(responseBody);

                // Groq response format: choices[0].message.content
                return json
                        .path("choices")
                        .path(0)
                        .path("message")
                        .path("content")
                        .asText("Tôi không thể trả lời lúc này.");
            }

        } catch (IOException e) {
            return "Xin lỗi, không thể kết nối với AI. "
                    + "Vui lòng thử lại.";
        }
    }

    private String buildCycleContext(User user) {
        // Get recent 30 entries for context
        List<CycleEntry> recentEntries = cycleEntryRepository
            .findByUserIdOrderByDateDesc(user.getId())
            .stream().limit(30).toList();

        StringBuilder sb = new StringBuilder();
        sb.append("Dữ liệu chu kỳ gần đây của người dùng:\n");

        if (recentEntries.isEmpty()) {
            sb.append("Chưa có dữ liệu chu kỳ.\n");
        } else {
            sb.append("Có ").append(recentEntries.size())
              .append(" ngày được ghi chép.\n");
            sb.append("Ngày ghi chép gần nhất: ")
              .append(recentEntries.get(0).getDate()).append("\n");
        }

        return sb.toString();
    }

    private String buildSystemPrompt(String cycleContext, String userName) {
        return """
            Bạn là Luna, trợ lý AI thông minh trong app Luna Track — \
            ứng dụng theo dõi chu kỳ kinh nguyệt.

            Tên người dùng: %s

            %s

            Vai trò của bạn:
            - Trả lời câu hỏi về sức khỏe phụ nữ, chu kỳ kinh nguyệt
            - Giải thích các giai đoạn chu kỳ (Menstrual, Follicular, Ovulation, Luteal)
            - Gợi ý về dinh dưỡng, tập luyện theo từng phase
            - Phân tích triệu chứng và đưa ra lời khuyên phù hợp
            - Nhắc nhở về việc ghi chép nhật ký hàng ngày

            Quy tắc quan trọng:
            - Luôn trả lời bằng tiếng Việt trừ khi người dùng hỏi bằng tiếng Anh
            - Thân thiện, ấm áp, như người bạn đồng hành
            - KHÔNG chẩn đoán bệnh — luôn khuyên gặp bác sĩ khi cần
            - Câu trả lời ngắn gọn, dễ hiểu, có thể dùng emoji phù hợp
            - Nếu câu hỏi không liên quan đến sức khỏe phụ nữ, nhẹ nhàng chuyển hướng
            - Giữ câu trả lời dưới 200 từ trừ khi cần giải thích chi tiết
            """.formatted(userName != null ? userName : "bạn", cycleContext);
    }
}
