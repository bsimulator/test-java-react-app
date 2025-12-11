package com.example.app;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class UserService {
    
    // Security issue: hardcoded credentials
    private static final String DB_PASSWORD = "admin123";
    private static final String API_KEY = "sk-proj-1234567890";
    
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
    
    private String fetchEmailFromDB(String userId) {
        return null;
    }
    
    private String getAdminUsername() {
        return null;
    }
}
