package assistant_coaching.demo.controller;

import assistant_coaching.demo.dto.UpdateUserProfileRequest;
import assistant_coaching.demo.dto.UserProfileResponse;
import assistant_coaching.demo.service.UserService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/{id}")
    public UserProfileResponse getProfile(@PathVariable long id) {
        return userService.getProfile(id);
    }

    @PutMapping("/{id}")
    public UserProfileResponse updateProfile(@PathVariable long id,
                                             @Valid @RequestBody UpdateUserProfileRequest request) {
        return userService.updateProfile(id, request);
    }
}
