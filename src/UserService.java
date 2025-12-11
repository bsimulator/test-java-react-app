package com.example.app;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class UserService {

    // Security issue: hardcoded credentials
    private static final String DB_PASSWORD = "admin123";
    private static final String API_KEY = "sk-proj-1234567890";
    private static final String SECRET_TOKEN = "mySecretToken123";

    // New violation: SQL Injection vulnerability
    public void findUserByName(String username) {
        try {
            Statement stmt = DriverManager.getConnection("jdbc:mysql://localhost/mydb").createStatement();
            // SQL Injection risk - using string concatenation
            String query = "SELECT * FROM users WHERE username = '" + username + "'";
            ResultSet rs = stmt.executeQuery(query);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void loadAllUsers() {
        Connection conn = null;
        Statement stmt = null;

        try {
            conn = DriverManager.getConnection("jdbc:mysql://localhost/mydb", "root", DB_PASSWORD);
            stmt = conn.createStatement();

            // Performance issue: SELECT *
            ResultSet rs = stmt.executeQuery("SELECT * FROM users");

            while (rs.next()) {
                // Code quality issue: System.out instead of logger
                System.out.println("User ID: " + rs.getInt("id"));
                System.out.println("Username: " + rs.getString("username"));
            }

        } catch (Exception e) {
            // Bad practice: printStackTrace
            e.printStackTrace();
        }
        // Resource leak: connections not closed!
    }

    public String getUserEmail(String userId) {
        String email = null;
        try {
            email = fetchEmailFromDB(userId);
        } catch (Exception e) {
            // Empty catch block - swallows exception
        }
        return email;
    }

    public boolean isAdmin(String username) {
        String adminUser = getAdminUsername();
        // NPE risk: adminUser could be null
        return username.equals(adminUser);
    }

    public void startBackgroundTask() {
        // Thread safety issue
        new Thread(() -> {
            System.out.println("Background task running...");
            // TODO: Add proper error handling
        }).start();
    }

    public void testDebugMethod() {
        System.out.println("Debug mode active");
        // More hardcoded secrets
        String dbUrl = "jdbc:mysql://prod-server.com/users?password=prod123";
    }

    private String fetchEmailFromDB(String userId) {
        return null;
    }

    private String getAdminUsername() {
        return null;
    }
}
