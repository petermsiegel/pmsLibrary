﻿   {output}← {ignoreCase} Concord text

    ; ⎕IO; ⎕PW
    ; ∆DICT; Highlight; LineFmt; LNumFmt; Skip; Trim; Write; WordList; WordFmt
    ; CHAR_STD; CHAR_BOLD; WORD_LEN; LINE_LEN; LNUM_LEN; MAX_WIDTH
    ; count; len; line; lines; lNum; lNums; lNumField; match; offset; rec; recs; timerNs; word; wordRaw
    ; wCurL; wFreq_d; wRecs_d

    {}⎕SE.UCMD 'load  ∆DICT'
 
     :IF 0=⎕NC 'ignoreCase' ⋄ ignoreCase←1 ⋄ :ENDIF

  ⍝ Demo text...
    text← text {
        0≠≢⍺: ⍺
        0≠⎕NC '#.SHAKESPEARE': #.SHAKESPEARE 
        0:: 911 ⎕SIGNAL⍨'Something bad happened' 
            #.SHAKESPEARE← (⎕UCS 10)(≠⊆⊢) 5000↑13006↓⎕OR _←⎕SE.UCMD 'get ',⍵
            ⎕←'Loaded #.SHAKESPEARE'
            #.SHAKESPEARE
    }'https://ocw.mit.edu/ans7870/6/6.006/s08/lecturenotes/files/t8.shakespeare.txt' 

    ⎕IO←0
    ⎕PW← MAX_WIDTH← 160

    LNUM_LEN ← 4  
    LNumFmt← (⍕LNUM_LEN)∘{,⍵ ⎕FMT⍨ 'ZI',⍺}

    Trim← {⍵↓⍨+/∧\' '=⍵}

    timerNs← 10 ⎕DT 'J'
    Write←{ count +← 1 ⋄ output,←⊂⍕⍵ } ⋄ output← ⍬ ⋄ count← 0
    Write '***** CONCORDANCE BEGUN AT ', ⊃'%ISO%'(1200⌶) 1 ⎕DT ⊂⎕TS
    
    WordList←{
        '([:⎕]?[\w_∆⍙]+(?:''[\w_∆⍙]+)?)' ⎕S 0 1⊣⍵
    }
    
    Highlight←{ 
      line wordRaw←⍺ ⍵
      Repl←{ w←⍵ ⋄ B←⍵∊CHAR_STD ⋄ (B/w)←CHAR_EMPHASIS[CHAR_STD⍳B/w] ⋄ w}
      ('(?<![⎕:])\b',wordRaw,'\b') ⎕R {Repl ⍵.Lengths[0]↑⍵.Offsets[0]↓⍵.Block}   ⍠1 ⊣ Trim line
    }
  ⍝ BOLD, BOLD_ITAL are SANS fonts-- since they appear to line up better...
   CHAR_STD← ⎕A,⎕C⎕A  ⋄ CHAR_BOLD← ⎕UCS (⎕UCS '𝗔')+⍳52 ⋄ CHAR_BOLD_ITAL←  ⎕UCS(⎕UCS '𝘼')+⍳52
   CHAR_EMPHASIS← 1⊃ CHAR_BOLD CHAR_BOLD_ITAL

    Skip← ∊∘(⎕D,'⎕:')⊃         ⍝ Words starting with ⎕ or : are APL special vars: ignore.

    wFreq_d←  0 ∆DICT ⍬         ⍝ Word frequencies
    wRecs_d←  ⍬ ∆DICT ⍬         ⍝ Word to lNum and lines
    
    lNum←0 
    Write 'Source text' 
    LINE_LEN← MAX_WIDTH - LNUM_LEN + 3
    :FOR line :IN text
         lNum+←1  

         Write (LNumFmt lNum), ' | ',(LINE_LEN↑ line)
         
        wCurL←⍬
        :For offset len :IN  WordList line
            wordRaw←len↑ offset↓ line
            word← ⎕C⍣ignoreCase⊢ wordRaw 
            :IF Skip word ⋄ :Continue ⋄ :ENDIF 
            wCurL,← ⊂word wordRaw 
            word +wFreq_d.Do1 1
        :EndFor
      ⍝ For each word in this line, highlight all appearances of that word simultaneously.
      ⍝ To do that, we process repeat appearances (ignoring case) with the first.
        :For word wordRaw :IN wCurL/⍨ ≠⊃¨wCurL      
            word wRecs_d.Cat1 lNum (line Highlight wordRaw)
        :EndFor 
    :ENDFOR 
    Write ''

    WORD_LEN← ⌈/≢¨wFreq_d.Keys
    LINE_LEN← MAX_WIDTH- (LNUM_LEN + WORD_LEN + 2×3)   ⍝ 3 per ' | '
    
    WordFmt← WORD_LEN∘↑
    LineFmt← LINE_LEN∘↑

    Write 'Word Frequencies and Lines'
    wRecs_d.(SortBy ⎕C Keys)        ⍝ Ignore case when sorting, even if globally set to 0.
    :FOR word recs :IN wRecs_d.Items
         lNums← ∪⊃¨recs 
         Write (WordFmt word), ' ', ('[',']',⍨⍕wFreq_d.Get1 word),' ', 2↓∊(⊂', '),∘ ⍕ ¨lNums 
    :ENDFOR    
    Write ''

    Write 'Concordance'
    :FOR word recs :IN  wRecs_d.Items
         :FOR lNum line :IN recs
            Write (LNumFmt lNum), ' | ', (WordFmt word), ' | ', (LineFmt line)
         :ENDFOR 
    :ENDFOR
    Write ''
    Write '***** CONCORDANCE COMPLETE AT ', ⊃'%ISO%'(1200⌶) 1 ⎕DT 'J'
    Write '*****',count,'lines written.'
    Write '***** Elapsed time: ',(1E4÷⍨⌊1E4×1E¯9×timerNs -⍨ 10 ⎕DT 'J'),'sec'

    ⎕ED 'output'