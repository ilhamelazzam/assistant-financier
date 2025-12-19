package assistant_coaching.demo.repository;

import assistant_coaching.demo.model.Budget;
import assistant_coaching.demo.model.BudgetPeriodType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface BudgetRepository extends JpaRepository<Budget, Long> {

    boolean existsByCategoryIgnoreCaseAndPeriodYearAndPeriodMonth(String category, Integer periodYear, Integer periodMonth);

    boolean existsByCategoryIgnoreCaseAndPeriodYearAndPeriodMonthAndIdNot(
            String category, Integer periodYear, Integer periodMonth, Long id);

    @Query("""
            select b from Budget b
            where b.periodYear = :year and b.periodMonth = :month
            """)
    List<Budget> findByYearMonth(@Param("year") int year, @Param("month") int month);

    @Query("""
            select b from Budget b
            where b.periodType <> :monthly
              and b.customStart <= :windowEnd
              and (b.customEnd is null or b.customEnd >= :windowStart)
            """)
    List<Budget> findRangeBudgets(@Param("windowStart") LocalDate windowStart,
                                  @Param("windowEnd") LocalDate windowEnd,
                                  @Param("monthly") BudgetPeriodType monthly);

    @Query("""
            select count(b) > 0 from Budget b
            where lower(b.category) = lower(:category)
              and b.periodYear = :year and b.periodMonth = :month
            """)
    boolean isDuplicateCategory(@Param("category") String category,
                                @Param("year") int year,
                                @Param("month") int month);

    @Query("""
            select count(b) > 0 from Budget b
            where lower(b.category) = lower(:category)
              and b.customStart <= :windowEnd
              and (b.customEnd is null or b.customEnd >= :windowStart)
            """)
    boolean isDuplicateWithinRange(@Param("category") String category,
                                   @Param("windowStart") LocalDate windowStart,
                                   @Param("windowEnd") LocalDate windowEnd);

    @Query("""
            select count(b) > 0 from Budget b
            where lower(b.category) = lower(:category)
              and b.customStart <= :windowEnd
              and (b.customEnd is null or b.customEnd >= :windowStart)
              and b.id <> :id
            """)
    boolean isDuplicateWithinRangeExcludingId(@Param("category") String category,
                                              @Param("windowStart") LocalDate windowStart,
                                              @Param("windowEnd") LocalDate windowEnd,
                                              @Param("id") Long id);
}
