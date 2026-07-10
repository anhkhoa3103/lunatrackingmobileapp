package com.lunatrack.apilunatracking.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ChatResponse {
    private String message;
    private boolean success;
    private String error;

    public ChatResponse(String message) {
        this.message = message;
        this.success = true;
        this.error = null;
    }
}
