package com.lunatrack.apilunatracking.controller;

import com.lunatrack.apilunatracking.dto.CycleEntryDto;
import com.lunatrack.apilunatracking.service.CycleEntryService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/entries")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class CycleEntryController {

    private final CycleEntryService cycleEntryService;

    // POST /api/entries — save or update
    @PostMapping
    public ResponseEntity<CycleEntryDto> save(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody CycleEntryDto dto) {
        return ResponseEntity.ok(
                cycleEntryService.saveEntry(userDetails.getUsername(), dto));
    }

    // GET /api/entries — get all
    @GetMapping
    public ResponseEntity<List<CycleEntryDto>> getAll(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(
                cycleEntryService.getAllEntries(userDetails.getUsername()));
    }

    // GET /api/entries/2026-05-27 — get by date
    @GetMapping("/{date}")
    public ResponseEntity<CycleEntryDto> getByDate(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date) {
        CycleEntryDto entry =
                cycleEntryService.getEntryByDate(userDetails.getUsername(), date);
        return entry != null
                ? ResponseEntity.ok(entry)
                : ResponseEntity.notFound().build();
    }

    // GET /api/entries/range?start=2026-05-01&end=2026-05-27
    @GetMapping("/range")
    public ResponseEntity<List<CycleEntryDto>> getRange(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate end) {
        return ResponseEntity.ok(
                cycleEntryService.getEntriesInRange(
                        userDetails.getUsername(), start, end));
    }

    // DELETE /api/entries/2026-05-27
    @DeleteMapping("/{date}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date) {
        cycleEntryService.deleteEntry(userDetails.getUsername(), date);
        return ResponseEntity.noContent().build();
    }
}