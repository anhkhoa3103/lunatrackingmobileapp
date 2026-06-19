package com.lunatrack.apilunatracking.service;

import com.lunatrack.apilunatracking.dto.CycleEntryDto;
import com.lunatrack.apilunatracking.model.CycleEntry;
import com.lunatrack.apilunatracking.model.User;
import com.lunatrack.apilunatracking.repository.CycleEntryRepository;
import com.lunatrack.apilunatracking.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CycleEntryService {

    private final CycleEntryRepository cycleEntryRepository;
    private final UserRepository userRepository;

    // ── Save or update entry for today ───────────────────────
    public CycleEntryDto saveEntry(String email, CycleEntryDto dto) {
        User user = getUser(email);

        // Update if entry already exists for this date
        CycleEntry entry = cycleEntryRepository
                .findByUserIdAndDate(user.getId(), dto.getDate())
                .orElse(new CycleEntry());

        entry.setUser(user);
        entry.setDate(dto.getDate());
        entry.setFlow(dto.getFlow());
        entry.setMoods(dto.getMoods());
        entry.setSymptoms(dto.getSymptoms());
        entry.setEnergy(dto.getEnergy());
        entry.setSleep(dto.getSleep());
        entry.setNotes(dto.getNotes());

        return toDto(cycleEntryRepository.save(entry));
    }

    // ── Get all entries for user ──────────────────────────────
    public List<CycleEntryDto> getAllEntries(String email) {
        User user = getUser(email);
        return cycleEntryRepository
                .findByUserIdOrderByDateDesc(user.getId())
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ── Get entry by date ─────────────────────────────────────
    public CycleEntryDto getEntryByDate(String email, LocalDate date) {
        User user = getUser(email);
        return cycleEntryRepository
                .findByUserIdAndDate(user.getId(), date)
                .map(this::toDto)
                .orElse(null);
    }

    // ── Get entries in date range ─────────────────────────────
    public List<CycleEntryDto> getEntriesInRange(
            String email, LocalDate start, LocalDate end) {
        User user = getUser(email);
        return cycleEntryRepository
                .findByUserIdAndDateBetween(user.getId(), start, end)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ── Delete entry ──────────────────────────────────────────
    public void deleteEntry(String email, LocalDate date) {
        User user = getUser(email);
        cycleEntryRepository
                .findByUserIdAndDate(user.getId(), date)
                .ifPresent(cycleEntryRepository::delete);
    }

    // ── Helpers ───────────────────────────────────────────────
    private User getUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new UsernameNotFoundException("User not found: " + email));
    }

    private CycleEntryDto toDto(CycleEntry entry) {
        CycleEntryDto dto = new CycleEntryDto();
        dto.setId(entry.getId());
        dto.setDate(entry.getDate());
        dto.setFlow(entry.getFlow());
        dto.setMoods(entry.getMoods());
        dto.setSymptoms(entry.getSymptoms());
        dto.setEnergy(entry.getEnergy());
        dto.setSleep(entry.getSleep());
        dto.setNotes(entry.getNotes());
        return dto;
    }
}