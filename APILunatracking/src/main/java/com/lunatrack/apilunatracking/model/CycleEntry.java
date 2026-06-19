package com.lunatrack.apilunatracking.model;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;
import java.util.List;

@Entity
@Table(name = "cycle_entries")
@Data
public class CycleEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private LocalDate date;

    private String flow;      // none, light, medium, heavy

    @ElementCollection
    @CollectionTable(name = "entry_moods")
    private List<String> moods;

    @ElementCollection
    @CollectionTable(name = "entry_symptoms")
    private List<String> symptoms;

    private String energy;    // low, medium, high
    private String sleep;     // poor, ok, good
    private String notes;
}
