package com.carrom.competition.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class WebController {

    @GetMapping("/")
    public String landing() {
        return "landing";
    }

    @GetMapping("/players")
    public String players() {
        return "players";
    }

    @GetMapping("/tournaments")
    public String tournaments() {
        return "tournaments";
    }

    @GetMapping("/fixtures")
    public String fixtures() {
        return "fixtures";
    }

    @GetMapping("/results")
    public String results() {
        return "results";
    }
}
