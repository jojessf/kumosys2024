CREATE DATABASE kumosys;

CREATE TABLE kumosys.webdata (
   name              VARCHAR(24),
   url               VARCHAR(128),
   ts                DATETIME,
   utime             INT,
   res               TEXT,
   cachestr          VARCHAR(256),
   PRIMARY KEY (name)
);

CREATE TABLE kumosys.webdatalog (
   name              VARCHAR(24),
   url               VARCHAR(128),
   ts                DATETIME,
   utime             INT,
   res               TEXT,
   cachestr          VARCHAR(256)
);

CREATE TABLE kumosys.postlog (
   name              VARCHAR(24),
   url               VARCHAR(128),
   ts                DATETIME DEFAULT current_timestamp() ON UPDATE current_timestamp(),
   utime             INT,
   res               TEXT,
   cachestr          VARCHAR(256)
);
