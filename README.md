# HDGuard-Zaliczenie1-WdSO
Prosty skrypt bash służący do monitorowania i utrzymania danej ilości wolnego miejsca na konkretnej partycji.

## Opis
Głównym elementem repozytorium jest Skrypt Bash `hdguard.sh` służący do monitorowania ilosci wolnego miejsca na partycji `/home/$USER`. 
Po przekroczeniu wartości granicznej (wyrażonego w % wolnego miejsca na partycji podanego jako pierwszy argument do skryptu) na danej partycji, skrypt znajduje pliki według ustalonego kryterium i proponuje jedno z działan:

- przeniesienie plikow zaproponowanych wedlug kryterium na nosnik USB typu hotswap
- usuniecie zaproponowanych plikow
- anulowanie aktualnej operacji

Pliki sa wybierane tak, aby ich łaczna wielkość pozwoliła na powrót ilości wolnego miejsca na partycji do poziomu powyżej wartości granicznej.
Ponadto proponowane pliki musiały mieć prawa zapisu, być plikami (nie np. linkami) oraz nie być ukryte.
W przypadku zignorowania prośby o podjęcie działania, pojawia się ona ponownie przy nastepnym skanowaniu, które odbywa się co 1 min.
Skrypt monitoruje partycję ciągle, jednakże można go zatrzymać kombinacją Ctrl+C, nie powoduje to błędów w skrypcie.
Początkowym kryterium sortowania dla plików miała być data utworzenia pliku, jednakże z pozyskanych przeze mnie informacji wynikało, iż systemy typu unix nie zawsze zapisuje date utworzenia pliku, zatem jako kryterium wyboru plików do przetwarzania wykorzystana została zapisywana data modyfikacji pliku.
Podczas tworzenia starałem się tak ustalać nazwy zmiennych i funkcji, aby zwiększyć czytelność kodu oraz uniknąć dokumentacji dla tak małego projektu.
Dodatkowym celem była jak najlepsza prezentacja skryptu oraz wywarcie pozytywnego wrażenia u użytkownika.  
Data utworzenia repozytorium nie jest datą utworzenia skryptu. Repozytorium zostało utworzone w póżniejszym terminie, aby zaprezentować jedno z wykonanych podczas studiów zadań.

Autor: Maciej Krzysztof Piasecki