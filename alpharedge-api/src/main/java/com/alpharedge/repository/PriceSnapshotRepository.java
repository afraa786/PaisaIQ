package com.alpharedge.repository;

import com.alpharedge.document.PriceSnapshot;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PriceSnapshotRepository extends MongoRepository<PriceSnapshot, String> {
    Optional<PriceSnapshot> findTopByCoinIdOrderByFetchedAtDesc(String coinId);

    List<PriceSnapshot> findByCoinIdAndFetchedAtAfterOrderByFetchedAtDesc(
            String coinId, LocalDateTime after);

    Optional<PriceSnapshot> findTopByCoinIdAndFetchedAtBeforeOrderByFetchedAtDesc(
            String coinId, LocalDateTime before);
}
