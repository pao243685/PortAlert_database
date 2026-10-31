-- PortAlert esquema completo 

CREATE TYPE severity AS ENUM ('baja', 'media', 'alta', 'critica');

CREATE TYPE alert_status AS ENUM ('nueva', 'atendida', 'ignorada');

CREATE TABLE users (
	id SERIAL NOT NULL, 
	email VARCHAR(255) NOT NULL, 
	password_hash VARCHAR(255) NOT NULL, 
	totp_secret VARCHAR(255), 
	totp_enabled BOOLEAN DEFAULT FALSE NOT NULL, 
	totp_last_used_step BIGINT, 
	telegram_chat_id VARCHAR(64), 
	telegram_link_token_hash VARCHAR(64), 
	telegram_link_expires_at TIMESTAMP WITH TIME ZONE, 
	enroll_token_hash VARCHAR(64), 
	enroll_expires_at TIMESTAMP WITH TIME ZONE, 
	enroll_used_at TIMESTAMP WITH TIME ZONE, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (telegram_chat_id), 
	UNIQUE (telegram_link_token_hash), 
	UNIQUE (enroll_token_hash)
);

CREATE UNIQUE INDEX ix_users_email ON users (email);

CREATE TABLE rules (
	id SERIAL NOT NULL, 
	code VARCHAR(50) NOT NULL, 
	title VARCHAR(200) NOT NULL, 
	description TEXT NOT NULL, 
	severity severity NOT NULL, 
	recommendation TEXT NOT NULL, 
	enabled BOOLEAN DEFAULT TRUE NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (code)
);

CREATE TABLE file_reputations (
	sha256 VARCHAR(64) NOT NULL, 
	status VARCHAR(12) NOT NULL, 
	malicious INTEGER NOT NULL, 
	suspicious INTEGER NOT NULL, 
	total INTEGER NOT NULL, 
	checked_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (sha256)
);

CREATE TABLE hosts (
	id SERIAL NOT NULL, 
	user_id INTEGER NOT NULL, 
	name VARCHAR(100) NOT NULL, 
	os_family VARCHAR(20) NOT NULL, 
	os_version VARCHAR(100), 
	api_key_prefix VARCHAR(12) NOT NULL, 
	api_key_hash VARCHAR(255) NOT NULL, 
	last_seen TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	score INTEGER, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (user_id), 
	FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX ix_hosts_api_key_prefix ON hosts (api_key_prefix);

CREATE TABLE reports (
	id SERIAL NOT NULL, 
	host_id INTEGER NOT NULL, 
	received_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	score INTEGER, 
	PRIMARY KEY (id), 
	FOREIGN KEY(host_id) REFERENCES hosts (id) ON DELETE CASCADE
);

CREATE INDEX ix_reports_received_at ON reports (received_at);

CREATE INDEX ix_reports_host_id ON reports (host_id);

CREATE TABLE alerts (
	id SERIAL NOT NULL, 
	host_id INTEGER NOT NULL, 
	rule_id INTEGER, 
	port INTEGER, 
	title VARCHAR(200) NOT NULL, 
	message TEXT NOT NULL, 
	severity severity NOT NULL, 
	status alert_status NOT NULL, 
	confidence VARCHAR(10) DEFAULT 'media' NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	notified_at TIMESTAMP WITH TIME ZONE, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(host_id) REFERENCES hosts (id) ON DELETE CASCADE, 
	FOREIGN KEY(rule_id) REFERENCES rules (id) ON DELETE SET NULL
);

CREATE INDEX ix_alerts_status ON alerts (status);

CREATE INDEX ix_alerts_host_id ON alerts (host_id);

CREATE TABLE processes (
	id SERIAL NOT NULL, 
	report_id INTEGER NOT NULL, 
	pid INTEGER NOT NULL, 
	name VARCHAR(255) NOT NULL, 
	exe_path TEXT, 
	username VARCHAR(100), 
	sha256 VARCHAR(64), 
	package VARCHAR(200), 
	exe_deleted BOOLEAN NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(report_id) REFERENCES reports (id) ON DELETE CASCADE
);

CREATE INDEX ix_processes_report_id ON processes (report_id);

CREATE INDEX ix_processes_sha256 ON processes (sha256);

CREATE TABLE ports (
	id SERIAL NOT NULL, 
	report_id INTEGER NOT NULL, 
	process_id INTEGER, 
	port INTEGER NOT NULL, 
	protocol VARCHAR(10) NOT NULL, 
	bind_address VARCHAR(64) NOT NULL, 
	service_name VARCHAR(100), 
	PRIMARY KEY (id), 
	FOREIGN KEY(report_id) REFERENCES reports (id) ON DELETE CASCADE, 
	FOREIGN KEY(process_id) REFERENCES processes (id) ON DELETE SET NULL
);

CREATE INDEX ix_ports_report_id ON ports (report_id);

CREATE INDEX ix_ports_port ON ports (port);
