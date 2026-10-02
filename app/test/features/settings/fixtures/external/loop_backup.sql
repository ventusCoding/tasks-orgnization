CREATE TABLE Habits (id INTEGER PRIMARY KEY, archived INTEGER, color INTEGER, description TEXT, freq_den INTEGER, freq_num INTEGER, highlight INTEGER, name TEXT, position INTEGER, reminder_hour INTEGER, reminder_min INTEGER, reminder_days INTEGER NOT NULL DEFAULT 127, type INTEGER NOT NULL DEFAULT 0, target_type INTEGER NOT NULL DEFAULT 0, target_value REAL NOT NULL DEFAULT 0, unit TEXT NOT NULL DEFAULT '', question TEXT, uuid TEXT);
CREATE TABLE Repetitions (id INTEGER PRIMARY KEY, habit INTEGER NOT NULL REFERENCES Habits(id), timestamp INTEGER NOT NULL, value INTEGER NOT NULL);
INSERT INTO Habits VALUES (1, 0, 5, '', 1, 1, 0, 'Read', 0, NULL, NULL, 127, 0, 0, 0, '', 'Did you read?', 'a1');
INSERT INTO Habits VALUES (2, 0, 2, '', 7, 1, 0, 'Weekly call', 1, NULL, NULL, 127, 0, 0, 0, '', '', 'a2');
INSERT INTO Repetitions VALUES (1, 1, 1758499200000, 2);
INSERT INTO Repetitions VALUES (2, 1, 1758585600000, 2);
INSERT INTO Repetitions VALUES (3, 1, 1758412800000, 3);
INSERT INTO Repetitions VALUES (4, 2, 1758499200000, 2);
