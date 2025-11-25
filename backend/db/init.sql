-- Enable PostGIS (if not already enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Drop tables if they exist to allow for clean re-creation
DROP TABLE IF EXISTS photos CASCADE;
DROP TABLE IF EXISTS deceased CASCADE;
DROP TABLE IF EXISTS graves CASCADE;

-- TABLE: graves
CREATE TABLE graves (
    id SERIAL PRIMARY KEY,
    section TEXT NOT NULL,
    grave_number TEXT NOT NULL,
    type TEXT,
    condition TEXT,
    leaseholder TEXT,
    expiration DATE,
    geom geometry(POLYGON, 4326)
);

-- Index for spatial queries
CREATE INDEX graves_geom_idx ON graves USING GIST (geom);

-- TABLE: deceased
CREATE TABLE deceased (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    birth_year INT,
    death_year INT,
    grave_id INT REFERENCES graves(id) ON DELETE CASCADE
);

-- TABLE: photos
CREATE TABLE photos (
    id SERIAL PRIMARY KEY,
    grave_id INT REFERENCES graves(id) ON DELETE CASCADE,
    url TEXT NOT NULL
);

-- DUMMY DATA

-- Graves
INSERT INTO graves (section, grave_number, type, condition, leaseholder, expiration, geom) VALUES
('A', '1', 'Burial', 'Good', 'John Doe', '2030-01-01', ST_GeomFromText('POLYGON((18.20930 49.88230, 18.20930 49.88240, 18.20940 49.88240, 18.20940 49.88230, 18.20930 49.88230))', 4326)),
('A', '2', 'Cremation', 'Fair', 'Jane Smith', '2032-05-15', ST_GeomFromText('POLYGON((18.20925 49.88235, 18.20925 49.88245, 18.20935 49.88245, 18.20935 49.88235, 18.20925 49.88235))', 4326)),
('B', '3', 'Burial', 'Excellent', 'Robert Johnson', '2028-11-20', ST_GeomFromText('POLYGON((18.20920 49.88220, 18.20920 49.88230, 18.20930 49.88230, 18.20930 49.88220, 18.20920 49.88220))', 4326)),
('B', '4', 'Family Plot', 'Good', 'Emily Davis', '2035-03-10', ST_GeomFromText('POLYGON((18.20915 49.88225, 18.20915 49.88235, 18.20925 49.88235, 18.20925 49.88225, 18.20915 49.88225))', 4326)),
('C', '5', 'Burial', 'Poor', 'Michael Brown', '2026-08-01', ST_GeomFromText('POLYGON((18.20940 49.88240, 18.20940 49.88250, 18.20950 49.88250, 18.20950 49.88240, 18.20940 49.88240))', 4326)),
('C', '6', 'Cremation', 'Good', 'Jessica Wilson', '2031-06-25', ST_GeomFromText('POLYGON((18.20945 49.88245, 18.20945 49.88255, 18.20955 49.88255, 18.20955 49.88245, 18.20945 49.88245))', 4326)),
('D', '7', 'Burial', 'Fair', 'David Moore', '2033-02-14', ST_GeomFromText('POLYGON((18.20910 49.88210, 18.20910 49.88220, 18.20920 49.88220, 18.20920 49.88210, 18.20910 49.88210))', 4326)),
('D', '8', 'Family Plot', 'Excellent', 'Sarah Taylor', '2034-09-05', ST_GeomFromText('POLYGON((18.20905 49.88215, 18.20905 49.88225, 18.20915 49.88225, 18.20915 49.88215, 18.20905 49.88215))', 4326)),
('E', '9', 'Burial', 'Good', 'Chris Anderson', '2029-04-30', ST_GeomFromText('POLYGON((18.20950 49.88250, 18.20950 49.88260, 18.20960 49.88260, 18.20960 49.88250, 18.20950 49.88250))', 4326)),
('E', '10', 'Cremation', 'Fair', 'Patricia Thomas', '2030-10-10', ST_GeomFromText('POLYGON((18.20955 49.88255, 18.20955 49.88265, 18.20965 49.88265, 18.20965 49.88255, 18.20955 49.88255))', 4326));

-- Deceased
INSERT INTO deceased (name, birth_year, death_year, grave_id) VALUES
('Alfred Adams', 1900, 1970, 1),
('Betty Adams', 1905, 1980, 1),
('Charles Adams', 1930, 2000, 1),

('David Brown', 1910, 1985, 2),
('Eleanor Brown', 1915, 1990, 2),

('Frank Green', 1920, 1995, 3),
('Grace Green', 1925, 2005, 3),
('Henry Green', 1950, 2020, 3),

('Irene Hall', 1930, 2010, 4),
('Jack Hall', 1935, 2015, 4),

('Karen King', 1940, 2000, 5),

('Liam Lewis', 1945, 2018, 6),
('Mia Lewis', 1950, 2022, 6),

('Noah Nash', 1955, 2005, 7),
('Olivia Nash', 1960, 2010, 7),

('Peter Price', 1965, 2012, 8),
('Quinn Price', 1970, 2019, 8),

('Rachel Reed', 1975, 2010, 9),
('Sam Reed', 1980, 2023, 9),

('Tina Turner', 1985, 2020, 10),
('Ulysses Usher', 1990, NULL, 10);

-- Photos
INSERT INTO photos (grave_id, url) VALUES
(1, 'https://via.placeholder.com/150/0000FF/FFFFFF?text=Grave+1+Pic+1'),
(1, 'https://via.placeholder.com/150/0000FF/FFFFFF?text=Grave+1+Pic+2'),

(2, 'https://via.placeholder.com/150/FF0000/FFFFFF?text=Grave+2+Pic+1'),

(3, 'https://via.placeholder.com/150/00FF00/FFFFFF?text=Grave+3+Pic+1'),
(3, 'https://via.placeholder.com/150/00FF00/FFFFFF?text=Grave+3+Pic+2'),

(4, 'https://via.placeholder.com/150/FFFF00/000000?text=Grave+4+Pic+1'),

(5, 'https://via.placeholder.com/150/FF00FF/FFFFFF?text=Grave+5+Pic+1'),

(6, 'https://via.placeholder.com/150/00FFFF/000000?text=Grave+6+Pic+1'),
(6, 'https://via.placeholder.com/150/00FFFF/000000?text=Grave+6+Pic+2'),

(7, 'https://via.placeholder.com/150/800000/FFFFFF?text=Grave+7+Pic+1'),

(8, 'https://via.placeholder.com/150/008000/FFFFFF?text=Grave+8+Pic+1'),
(8, 'https://via.placeholder.com/150/008000/FFFFFF?text=Grave+8+Pic+2'),

(9, 'https://via.placeholder.com/150/000080/FFFFFF?text=Grave+9+Pic+1'),

(10, 'https://via.placeholder.com/150/808000/FFFFFF?text=Grave+10+Pic+1');
