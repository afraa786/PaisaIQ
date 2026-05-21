package com.alpharedge.repository;

import com.alpharedge.document.TradeTransaction;
import org.springframework.data.mongodb.repository.Aggregation;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TradeTransactionRepository extends MongoRepository<TradeTransaction, String> {

    List<TradeTransaction> findByUserId(String userId);

    List<TradeTransaction> findByUserIdAndCoinSymbol(String userId, String coinSymbol);

    List<TradeTransaction> findByUserIdAndFinancialYear(String userId, String financialYear);

    List<TradeTransaction> findByEntityType(TradeTransaction.EntityType entityType);

    List<TradeTransaction> findByUserIdAndExchangeName(String userId, String exchangeName);

    @Aggregation(pipeline = {
        "{ $match: { userId: ?0, financialYear: ?1, type: 'SELL' } }",
        "{ $group: { _id: null, total: { $sum: '$tdsPaid' } } }"
    })
    Optional<TdsSum> sumTdsByUserAndFY(String userId, String financialYear);

    default double sumTdsPaid(String userId, String financialYear) {
        return sumTdsByUserAndFY(userId, financialYear)
                .map(TdsSum::getTotal)
                .orElse(0.0);
    }

    default List<TradeTransaction> bulkInsert(List<TradeTransaction> trades) {
        return saveAll(trades);
    }

    interface TdsSum {
        double getTotal();
    }
}
