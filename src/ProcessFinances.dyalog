 Process 
    ; _; __; aggregate; amount; amountIx; badNm; badP; badRecs
    ; categoryIx; data; dataRaw; directory; fName; footer
    ; header; in; inFiles; outFi; sum; vNames; var; varFull 

amountIx←4
categoryIx←12

directory← '/Users/petermsiegel/Desktop/Keep 30 DAYS/'
inFiles← '2023YTD@Oct11' '2022'
vNames←  '2023'          '2022'
 
:FOR in var :ineach inFiles vNames
    ⎕←'>>> Loading file "', in, '.csv" from directory "',directory,'"'
    data← 1↓⎕CSV directory,in,'.csv'   ⍝ Remove header row
    
    :If 0<≢badRecs← data⌿⍨ badP← 0=≢¨data[;categoryIx]~¨' ' 
      badNm← 'bad_',var
    ⍝ Skip if 'autopay payment' in any field.
      :If 1∊ __←{~1∊'autopay payment'⍷⎕C ⍕⍵}¨ ↓badRecs  
        '  > Ignoring ',(⍕≢badRecs),' records in input file with **NO** category.  ',(⍕+/__),' are NOT "AUTOPAY PAYMENT"'
        '  > To review:'
        '    ⎕ED ''',badNm,''''
      :Else 
        '  > Ignoring ',(⍕≢badRecs),' records in input file with **NO** category.  **ALL** are "AUTOPAY PAYMENT"'
      :Endif 
      {}⍎badNm,'←badRecs'
    :Endif 
    data← data⌿⍨ ~badP
    
    amount←⍎¨data[;amountIx]
    '>>> GRAND TOTAL: $',2⍕sum←+/amount
    
  ⍝ All the real work is here!
  ⍝ Aggregate into:  
  ⍝    unique category, (no. records), (sum of amounts in dollars and cents)
  ⍝ Sort by aggregate categories
    aggregate←⍕{⍵[⍋⍵[;0];]} data[;categoryIx]{⍺,(≢⍵),10 2⍕+/⍵}⌸amount

    header← (_←¯1↑⍴aggregate)↑' >>> FILE "','" <<<',⍨in
    footer← _↑' GRAND TOTAL                                    ',10 2⍕sum
    aggregate← header⍪ aggregate ⍪ footer 
    aggregate← '-'@('¯'∘=) ⊣ aggregate

    ⎕←'We have calculated and sorted aggregate data from ',in
    ⎕←'>>> Aggregate data var:  "', '"',⍨ varFull←'agg_',var
    {}⍎varFull,'← aggregate'

    outFi← in,'_PMS.txt'
    (⊂↓aggregate) ⎕NPUT (directory,outFi) 1

    ⎕←'>>> Aggregate data file: "', outFi, '" in directory "', '"',⍨ directory
    ⎕←''

    ⎕ED ⍠('ReadOnly' 1)⊣'aggregate'
 
 :ENDFOR 