CREATE TABLE user_api_keys (
    user_id INT PRIMARY KEY REFERENCES users(id) NOT NULL,
    access_key CHAR(36) NOT NULL,
    secret_key CHAR(304) NOT NULL,
);
