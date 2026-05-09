<?php
/**
 * Admin Logout
 * ASTU-Q Admin Control Panel
 */

session_start();

// Destroy session
session_unset();
session_destroy();

// Redirect to login page
header('Location: admin_login.php');
exit;
?>
