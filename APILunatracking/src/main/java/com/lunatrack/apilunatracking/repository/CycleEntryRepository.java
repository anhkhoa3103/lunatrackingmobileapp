package com.lunatrack.apilunatracking.repository;

import com.lunatrack.apilunatracking.model.CycleEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface CycleEntryRepository extends JpaRepository<CycleEntry, Long> {

    List<CycleEntry> findByUserIdOrderByDateDesc(Long userId);

    Optional<CycleEntry> findByUserIdAndDate(Long userId, LocalDate date);

    List<CycleEntry> findByUserIdAndDateBetween(
            Long userId, LocalDate start, LocalDate end);
}
