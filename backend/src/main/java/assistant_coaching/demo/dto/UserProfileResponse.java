package assistant_coaching.demo.dto;

import java.time.LocalDate;

public class UserProfileResponse {

    private final Long id;
    private final String displayName;
    private final String email;
    private final String phoneNumber;
    private final String location;
    private final LocalDate memberSince;
    private final String bio;

    public UserProfileResponse(Long id,
                               String displayName,
                               String email,
                               String phoneNumber,
                               String location,
                               LocalDate memberSince,
                               String bio) {
        this.id = id;
        this.displayName = displayName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.location = location;
        this.memberSince = memberSince;
        this.bio = bio;
    }

    public Long getId() {
        return id;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getEmail() {
        return email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public String getLocation() {
        return location;
    }

    public LocalDate getMemberSince() {
        return memberSince;
    }

    public String getBio() {
        return bio;
    }
}
