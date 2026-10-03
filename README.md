# credit-risk-analysis-sql.
Kreditrisikoanalyse mit MySQL: Datenbereinigung, Ausfallquoten und risikobasiertes Monitoring.

SQL-Projekt zur Untersuchung von Kreditausfällen, Bonitätsklassen und möglichen Risikosignalen. Erstellt im Rahmen meiner Weiterbildung zur Data Analyst.

## Fragestellungen

- Wie unterscheiden sich die Ausfallquoten zwischen den Bonitätsklassen A bis G?
- Welche Zusammenhänge bestehen zwischen Kreditausfällen, Wohnstatus und früheren Zahlungsausfällen?
- Wie unterscheiden sich durchschnittliche Kredithöhe und gesamtes Kreditvolumen?
- Wie lassen sich Kredite anhand transparenter Regeln für das Monitoring gruppieren?

## Datenaufbereitung

Der Ausgangsdatensatz enthält **32.581 Datensätze**.

Die CSV-Datei wurde mit `LOAD DATA LOCAL INFILE` über den MySQL-Client in PowerShell importiert. Anschließend wurden Textwerte in geeignete Datentypen umgewandelt und leere numerische Felder als `NULL` behandelt.

Bei der Plausibilitätsprüfung wurden sieben Datensätze ausgeschlossen:

- fünf mit einem Alter über 100 Jahren;
- zwei mit einer Beschäftigungsdauer von 123 Jahren.

Die bereinigte Analysebasis enthält **32.574 Datensätze**.

Fehlende Werte bleiben erhalten. Auch Datensätze mit identischen Merkmalen werden nicht automatisch gelöscht, da der Ausgangsdatensatz keine eindeutige Kredit-ID enthält.

## Zentrale Ergebnisse

| Kennzahl | Ergebnis |
|---|---:|
| Bereinigte Datensätze | 32.574 |
| Kredite mit Ausfall | 7.107 |
| Gesamte Ausfallquote | 21,82 % |
| Ausfallquote bei Kreditbetrag/Einkommen über 30 % | 70,3 % |
| Ausfallquote bei Kreditbetrag/Einkommen bis 30 % | 15,4 % |

### Ausfallquote nach Bonitätsklasse

| Klasse | Anzahl Kredite | Ausfallquote |
|---|---:|---:|
| A | 10.776 | 10,0 % |
| B | 10.448 | 16,3 % |
| C | 6.456 | 20,7 % |
| D | 3.625 | 59,0 % |
| E | 964 | 64,4 % |
| F | 241 | 70,5 % |
| G | 64 | 98,4 % |

Die Klassen A und B enthalten die meisten Kredite. Die durchschnittliche Kredithöhe ist dagegen in den Klassen mit höherem Risiko größer. Kreditanzahl, durchschnittliche Kredithöhe und gesamtes Kreditvolumen werden deshalb getrennt betrachtet.

## Regelbasiertes Monitoring

Die Zuordnung erfolgt in dieser Reihenfolge:

1. **Hohe Intensität:** Klasse D bis G, Kreditbetrag/Einkommen über 30 % oder früherer Zahlungsausfall.
2. **Mittlere Intensität:** Klasse B oder C ohne eines der oben genannten Risikosignale.
3. **Niedrige Intensität:** übrige Kredite.

Diese Einteilung ist eine explorative Regel und kein trainiertes Prognosemodell.

## Einordnung und Grenzen

- `loan_percent_income` beschreibt das Verhältnis von Kreditbetrag zu Einkommen, nicht die monatliche Ratenbelastung.
- Fehlende Zinssätze werden bei der Berechnung des durchschnittlichen Zinssatzes nicht berücksichtigt.
- Die Klasse G umfasst nur 64 Kredite. Ihre Ausfallquote ist daher vorsichtig zu interpretieren.
- Die Ergebnisse zeigen Zusammenhänge im Datensatz und belegen keine Ursachen.
- Ohne Informationen zu internen Vergaberichtlinien lässt sich kein Regelverstoß feststellen.

## Verwendete Werkzeuge

- MySQL
- MySQL Workbench
- PowerShell
- Microsoft PowerPoint
