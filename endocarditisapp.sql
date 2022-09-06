-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost:8889
-- Generation Time: Sep 05, 2022 at 10:29 AM
-- Server version: 5.7.34
-- PHP Version: 7.4.21

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `endocarditisapp`
--

-- --------------------------------------------------------

--
-- Table structure for table `benutzer`
--

CREATE TABLE `benutzer` (
  `benutzername` varchar(256) NOT NULL,
  `passwort_hash` varchar(256) NOT NULL,
  `admin` int(11) NOT NULL,
  `ist_arzt` int(11) NOT NULL,
  `patienten_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `benutzer`
--

INSERT INTO `benutzer` (`benutzername`, `passwort_hash`, `admin`, `ist_arzt`, `patienten_id`) VALUES
('admin', '$2a$12$CxIntUf/5mnCYq8CwxGUu.lN0SuqG4GsJj2VljwC/VgxUqrqe6NWe', 1, 1, 1),
('arzt1', '$2a$12$H7vMT1.mvN1HjKslGwEvVeL5.9n8lj1ZXcgunG5zhQc/J.r392tla', 0, 1, 1),
('arzt2', '$2a$12$PZ3cQXBcHGUQyZ56F8.OMOJTXvlfsvLGWKxee1zpLNFwMHhM1KusC', 0, 1, 2),
('arzt3', '$2a$12$Is2xTvRvbKU9wln1hK.8meYCgvXTpdxkziDBOnwSVgxmB8wo8GmoG', 0, 1, 3),
('pat1', '$2a$12$6xvracpVQKXUyFPc4dTHzOVoKNYRvhYpmcn0nqa3LvfMk1Wfrn7sm', 0, 0, 1),
('pat2', '$2a$12$HNDJFU3/Z8cEe/eE/08KzuR/15wDg1oc2HSGtHr9XrxVdOsm3BG1C', 0, 0, 2),
('pat3', '$2a$12$hfggXhBRZAr.OmyhFy3KW.Ml6ZSrJwikv0zpq.v04/3buZiVLp4xq', 0, 0, 3),
('pat4', '$2a$12$spb.Zw2su/2FqrqNBzfZ.enG3yjGesxCfmFIqWteJKKaGuxRHATJu', 0, 0, 4);

-- --------------------------------------------------------

--
-- Table structure for table `patienten`
--

CREATE TABLE `patienten` (
  `id` int(11) NOT NULL,
  `vorname` varchar(20) NOT NULL,
  `nachname` varchar(30) NOT NULL,
  `geburtsdatum` date NOT NULL DEFAULT '1990-01-01',
  `beginn` date NOT NULL,
  `ende` date NOT NULL,
  `geschlecht` tinyint(4) NOT NULL DEFAULT '1',
  `vorgeschichte` text NOT NULL,
  `arztkontakt` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `patienten`
--

INSERT INTO `patienten` (`id`, `vorname`, `nachname`, `geburtsdatum`, `beginn`, `ende`, `geschlecht`, `vorgeschichte`, `arztkontakt`) VALUES
(1, 'Markus', 'Mustermann', '1991-01-01', '2022-07-01', '2023-01-31', 1, 'folgt', 'Dr. Hilfreich\nTelefon 01234-5456788\nemail praxis@doktor-hilfreich.kardiologe.de'),
(2, 'Maria', 'Musterfrau', '1982-02-02', '2022-06-01', '2022-12-31', 2, 'folgt', 'Dr. Anton Herzlich\nPraxis 0987-6544321\nin NotfÃ¤llen 0155-19283746\n'),
(3, 'Jo', 'Mustermensch', '2003-03-03', '2022-07-15', '2022-07-31', 3, 'folgt', 'PD Dr. A. von Herz\nTelefon 08474-314768'),
(5, 'Ungueltig', 'Invalid', '1990-01-01', '2022-09-01', '2022-09-08', 1, '', '');

-- --------------------------------------------------------

--
-- Table structure for table `tagebuch_eintraege`
--

CREATE TABLE `tagebuch_eintraege` (
  `id` int(11) NOT NULL,
  `patienten_id` int(11) NOT NULL,
  `datum` date NOT NULL,
  `fieber` tinyint(1) NOT NULL,
  `fieber_temperatur` decimal(3,1) DEFAULT NULL,
  `kopfschmerzen` tinyint(1) NOT NULL,
  `abgeschlagenheit` tinyint(1) NOT NULL,
  `appetitlosigkeit` tinyint(1) NOT NULL,
  `nachtschweiss` tinyint(4) NOT NULL,
  `muskel_gelenkschmerzen` tinyint(4) NOT NULL,
  `zuletzt_geaendert` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tagebuch_eintraege`
--

INSERT INTO `tagebuch_eintraege` (`id`, `patienten_id`, `datum`, `fieber`, `fieber_temperatur`, `kopfschmerzen`, `abgeschlagenheit`, `appetitlosigkeit`, `nachtschweiss`, `muskel_gelenkschmerzen`, `zuletzt_geaendert`) VALUES
(1, 1, '2022-08-31', 0, NULL, 1, 1, 0, 0, 0, '2022-09-03'),
(3, 1, '2022-09-01', 1, '38.4', 1, 1, 0, 0, 1, '2022-09-04'),
(4, 1, '2022-08-29', 0, NULL, 0, 0, 0, 0, 0, '2022-09-01'),
(5, 1, '2022-08-30', 0, NULL, 0, 1, 0, 0, 0, '2022-09-03'),
(6, 1, '2022-09-02', 1, '39.8', 0, 1, 0, 0, 1, '2022-09-05'),
(18, 1, '2022-09-03', 1, '39.2', 0, 1, 1, 0, 1, '2022-09-04');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `benutzer`
--
ALTER TABLE `benutzer`
  ADD PRIMARY KEY (`benutzername`);

--
-- Indexes for table `patienten`
--
ALTER TABLE `patienten`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tagebuch_eintraege`
--
ALTER TABLE `tagebuch_eintraege`
  ADD UNIQUE KEY `entryID` (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `patienten`
--
ALTER TABLE `patienten`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `tagebuch_eintraege`
--
ALTER TABLE `tagebuch_eintraege`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
