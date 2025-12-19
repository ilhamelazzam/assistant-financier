package assistant_coaching.demo.model;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "app_user")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String displayName;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "password_hash")
    private String passwordHash;

    private String phoneNumber;

    private String location;

    private String bio;

    private LocalDate memberSince;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<FinancialGoal> goals = new ArrayList<>();

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CoachingSession> sessions = new ArrayList<>();

    protected User() {
        // JPA
    }

    public User(String email, String displayName) {
        this.email = email;
        this.displayName = displayName;
        this.createdAt = LocalDateTime.now();
        this.memberSince = LocalDate.now();
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    @PrePersist
    private void onPersist() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (memberSince == null) {
            memberSince = LocalDate.now();
        }
    }

    public Long getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getBio() {
        return bio;
    }

    public void setBio(String bio) {
        this.bio = bio;
    }

    public LocalDate getMemberSince() {
        return memberSince;
    }

    public void setMemberSince(LocalDate memberSince) {
        this.memberSince = memberSince;
    }

    public List<FinancialGoal> getGoals() {
        return goals;
    }

    public void addGoal(FinancialGoal goal) {
        goals.add(goal);
        goal.setUser(this);
    }

    public List<CoachingSession> getSessions() {
        return sessions;
    }

    public void addSession(CoachingSession session) {
        sessions.add(session);
        session.setUser(this);
    }
}
