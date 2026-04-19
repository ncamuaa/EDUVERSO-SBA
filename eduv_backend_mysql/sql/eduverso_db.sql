CREATE DATABASE IF NOT EXISTS eduverso_db;
USE eduverso_db;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(120) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (full_name, email, password)
VALUES
('Demo Student', 'demo@eduverso.com', '$2a$10$2sF0yQw6gGdIYv3aJxjFAe6Q/6Q9wP5zP9QJq3lP2XcVnQ3Qyq8PO');
/*
Demo password for the sample row above:
password123
You can remove this row if you want a clean database.
*/
