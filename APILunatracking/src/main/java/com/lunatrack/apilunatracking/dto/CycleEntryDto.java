package com.lunatrack.apilunatracking.dto;

import lombok.Data;
import java.time.LocalDate;
import java.util.List;

@Data
public class CycleEntryDto {
    private Long id;
    private LocalDate date;
    private String flow;
    private List<String> moods;
    private List<String> symptoms;
    private String energy;
    private String sleep;
    private String notes;
}