<?php
/**
 * Test Database Connection and Table Structure
 * Debug file for admin approval system
 */

require_once 'db_connection.php';

header("Content-Type: application/json");

try {
    // Test database connection
    echo json_encode(['success' => true, 'message' => 'Database connection successful']);
    
    // Test questions table structure
    $stmt = $pdo->query("DESCRIBE questions");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true, 
        'message' => 'Questions table structure',
        'columns' => $columns
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        'success' => false, 
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    echo json_encode([
        'success' => false, 
        'message' => 'General error: ' . $e->getMessage()
    ]);
}
?>
