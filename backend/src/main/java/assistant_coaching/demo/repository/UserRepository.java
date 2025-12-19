package assistant_coaching.demo.repository;

import assistant_coaching.demo.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);

    boolean existsByEmailIgnoreCaseAndIdNot(String email, Long id);
}
