package com.lunatrack.apilunatracking.controller;

import com.lunatrack.apilunatracking.dto.ChatRequest;
import com.lunatrack.apilunatracking.dto.ChatResponse;
import com.lunatrack.apilunatracking.service.AiChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AiChatController {

    private final AiChatService aiChatService;

    @PostMapping
    public ResponseEntity<ChatResponse> chat(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody ChatRequest request) {
        try {
            String response = aiChatService.chat(
                userDetails.getUsername(), request);
            return ResponseEntity.ok(new ChatResponse(response));
        } catch (Exception e) {
            return ResponseEntity.ok(new ChatResponse(
                "Xin lỗi, đã xảy ra lỗi. Vui lòng thử lại.",
                false,
                e.getMessage()));
        }
    }
}
