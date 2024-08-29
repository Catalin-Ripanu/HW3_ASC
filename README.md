Nume: Cătălin-Alexandru Rîpanu

Grupa: 333CC

# Tema 3 - ASC

### Organizare
Tema a constat în proiectarea unei structuri de date **Hash Table** cu ajutorul
plăcii grafice (GPU) astfel încât manipularea datelor să fie cât mai simplă și
rapidă. S-a ales varianta **Linear probing** pentru organizarea structurii de
date întrucât este cea mai trivială și intuitivă dintre cele prezentate în cadrul
enunțului. Ei bine, accesul la elementele hashtable-ului in cazul unei coliziuni
se face rapid întrucât următorii indecși testați în cadrul metodelor clasei
**GpuHashTable**, după calcularea hash-ului cheii, sunt adiacenți, ceea ce conferă
localitate spațială implementării. Această localitate îmbunătățește rata de *hit* în
cache-urile GPU-ului, ceea ce duce la un *timp mai mic* de acces la date in general.

### Implementare
Clasa *GpuHashTable* reține un câmp important, și anume _hashTable_, care reprezintă
tabela ce va avea obiecte *Entry* care vor stoca perechile adăugate în Hash Table,
numărul maxim de elemente ce pot fi stocate (capacity), precum și numărul real de
elemente stocate (size).

**Funcția de Hash** 
Funcția a fost concepută folosind mai multe funcții întâlnite în diverse părți.
Numărul mare de operații efectuate de această funcție mărește uniformitatea
distribuției rezultatelor acesteia.

**Insert Batch** 
Inițial, funcția va copia din RAM in VRAM cheile și valorile care trebuie adăugate,
după care va lansa în execuție kernel-urile care fac efectiv inserarea în Hash Table,
câte unul pentru fiecare element adăugat. Numărul de thread-uri pe fiecare bloc este
numărul maxim admis de *GPU*, pentru a maximiza paralelismul. S-a observat că viteza
maximă este obținută atunci când blocurile de thread-uri au dimensiunea maximă
posibilă, adică 1024. Când o poziție din Hash Table este deja ocupată de altă cheie,
se incearcă următoarea poziție parcurgându-se circular vectorul *entries*. Având în
vedere că procentajul de încărcare al tabelei este subunitar, se garantează că se
va găsi întotdeauna o poziție la care să se adauge o nouă pereche cheie - valoare.
La fiecare pas se folosește funcția atomică de Compare-And-Set pentru a încerca
aceste poziții. Mai mult decât atât, *atomicCAS()* acționează ca un mutex (urmatoarele
apeluri nu vor putea să scrie la acea adresa atunci când acesta intoarce KEY_INVALID
sau cheia de la indexul thread-ului).

**Get Bach**
Găsirea cheii funcționează similar cu cea din *insertBatch()*, cu excepția faptului că
nu mai este nevoie de *atomicCas()* întrucât tabela nu se mai modifică. Prin urmare,
fiecare thread va căuta una dintre cheile cu valorile cerute, se calculează hash-ul
la fel ca mai sus și când cheia de la poziția indicată de hash este cea cautată, se
scrie într-un vector partajat GPU <-> RAM valoarea acesteia.

**Reshape**
Se alocă spațiu pentru noile perechi și se umple cu 0 acel spațiu. De asemenea, se
pornește câte un thread pentru fiecare poziție din tabela veche. Dacă la această
poziție nu există o cheie validă, firul se incheie. În caz contrar, urmează ca
valoarea asociată cheii să se adauge in tabela nou alocată în același mod ca in cazul
kernel-ului apelat de *insertBatch()*.

**Rezultate**
În urma execuției, se obține următoarea ieșire:

```
------- Test T1 START   ----------

HASH_BATCH_INSERT   count: 500000           speed: 72M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 500000           speed: 59M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 500000           speed: 82M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 500000           speed: 74M/sec          loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 65 M/sec,   AVG_GET: 78 M/sec,      MIN_SPEED_REQ: 0 M/sec  


------- Test  T1 END    ----------       [ OK RESULT:  15  pts ]

Total so far:  15 / 80



------- Test T2 START   ----------

HASH_BATCH_INSERT   count: 1000000          speed: 105M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 1000000          speed: 77M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 131M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 112M/sec         loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 91 M/sec,   AVG_GET: 122 M/sec,     MIN_SPEED_REQ: 20 M/sec 


------- Test  T2 END    ----------       [ OK RESULT:  15  pts ]

Total so far:  30 / 80



------- Test T3 START   ----------

HASH_BATCH_INSERT   count: 1000000          speed: 102M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 1000000          speed: 69M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 1000000          speed: 58M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 1000000          speed: 49M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 104M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 113M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 114M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 98M/sec          loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 70 M/sec,   AVG_GET: 107 M/sec,     MIN_SPEED_REQ: 40 M/sec 


------- Test  T3 END    ----------       [ OK RESULT:  15  pts ]

Total so far:  45 / 80



------- Test T4 START   ----------

HASH_BATCH_INSERT   count: 20000000         speed: 169M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 20000000         speed: 140M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 20000000         speed: 98M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 20000000         speed: 78M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 20000000         speed: 212M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 20000000         speed: 158M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 20000000         speed: 136M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 20000000         speed: 127M/sec         loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 121 M/sec,  AVG_GET: 158 M/sec,     MIN_SPEED_REQ: 50 M/sec 


------- Test  T4 END    ----------       [ OK RESULT:  15  pts ]

Total so far:  60 / 80



------- Test T5 START   ----------

HASH_BATCH_INSERT   count: 50000000         speed: 178M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 50000000         speed: 134M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 50000000         speed: 204M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 50000000         speed: 148M/sec         loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 156 M/sec,  AVG_GET: 176 M/sec,     MIN_SPEED_REQ: 50 M/sec 


------- Test  T5 END    ----------       [ OK RESULT:  10  pts ]

Total so far:  70 / 80



------- Test T6 START   ----------

HASH_BATCH_INSERT   count: 10000000         speed: 168M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 124M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 99M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 79M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 67M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 59M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 51M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 40M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 40M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 37M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 150M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 146M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 196M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 155M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 156M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 147M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 141M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 137M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 147M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 116M/sec         loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 76 M/sec,   AVG_GET: 149 M/sec,     MIN_SPEED_REQ: 50 M/sec 


------- Test  T6 END    ----------       [ OK RESULT:  10  pts ]

Total so far:  80 / 80

Total: 80 / 80
```

Am ales să redimensionez tabela când factorul de umplere ajunge la 90% astfel
incât noul factor de umplere să ajungă în jur de 85%.

Se observă că pe masură ce dimensiunea tabelei crește, overhead-ul este
din ce in ce mai mic (se recalculează hash-urile cheilor prin funcția *reshape()*
descrisă mai sus).

Eliminând sincronizarea, se observa că, nemodificând tabela și neavând nevoie de operații
atomice și nici de *reshape()*, funcția *getBatch()* rulează cu mult mai repede
decât inserarea.

Aprox 50% din timpul de rulare este petrecut in apeluri de sistem, deci se aloca
și se elimină memorie (VRAM) de pe GPU. In restul de timp se realizeaza inserearea
sau extragerea efectivă. Este de așteptat ca majoritatea timpului consumat să fie 
în *Memcpy()* sau *Memset()* deoarece datele trebuie să parcurga un drum cu anumite
limitări (CPU->Placa_de_bază->RAM->Placa_de_bază->CPU->Placa_de_bază->GPU).

Acest overhead nu poate fi, insă, evitat, având în vedere alocarea datelor in RAM
facută în *test_map.cpp*, căci pentru a avea kernel-urile acces la date, este necesar
ca ele să fie copiate și în VRAM (GPU).

### Resurse Utilizate
1: https://ocw.cs.pub.ro/courses/asc/laboratoare/07

2: https://ocw.cs.pub.ro/courses/asc/laboratoare/08

3: https://ocw.cs.pub.ro/courses/asc/laboratoare/09

4: https://nosferalatu.com/SimpleGPUHashTable.html

5: https://www.geeksforgeeks.org/implementing-hash-table-open-addressing-linear-probing-cpp/

6: https://www.partow.net/programming/hashfunctions/

O tema interesanta.
Catalin-Alexandru Ripanu