 ∇ (rc outBuf)← ∆F_APL (opts escCh  fString)  
⍝      const char opts[5], const WIDE4 escCh, 
⍝      WIDE fString[],     INT4 fStringLen, 
⍝      WIDE outBuf[],      INT4 *outPLen
 
   mode←   opts[0]              ⍝  See modes (MODE_...) above
   debug←  opts[1]              ⍝  debug (boolean) 
   boxAll← opts[2]              ⍝  if 1, use B instead of M overall. 
   useNs←  opts[3]              ⍝  If 1, pass an anon ns to each Code Fn.           
   extLib← opts[4]              ⍝  If 0, pseudo-primitives are defined internally.
   crOut←  debug⊃ ⎕UCS 13 9229  ⍝  13: CR, 9229: ␍

  ⍝ NONE: not in a field, TF: in a text field, CF_START: starting a cf; CF: in a code field or space field */
  NONE TF CF_START CF← ⍳4
  state←NONE                         ⍝  what kind of field are we in: NONE, TF, CF_START, CF 
  oldState←NONE                      ⍝  last state
  bracketDepth←0                     ⍝  finding } closing a field.
  omegaNext←0                        ⍝  `⍵/⍹ processing.
  cfStart←0                          ⍝  Note start of code field in input-- for 'doc' processing.

   in← ⎕NS ⍬ 
    in.buf← fString
    in.cur← 0
   out← ⎕NS ⍬
    out.buf←  ''
    out.cur←   0                     ⍝  output buffer length/position; passed back to APL as *outPLen = out.cur;
⍝  Code buffer-- allows us to set aside generated code field (CF) code to the end, in case its a 
⍝     self-doc CF. If so, we output the doc literal text and append the processed CF code:
⍝           'code_text_verbatim_quoted' ("▶" | "▼") code_text_processed
    code← ⎕NS ⍬
    code.buf← ''
    code.cur← 0 

⍝  Code sequences...
mergeCd← extLib⊃  '{⎕ML←1⋄⍺←⊢⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}' ' ⎕SE.⍙.M '  
aboveCd← extLib⊃  '{⎕ML←1⋄⍺←⍬⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}' ' ⎕SE.⍙.A ' 
boxCd←   extLib?  '{⎕SE.Dyalog.Utils.disp},⍣(⊃0=⍴⍴⍵)⊢⍵}'  ' ⎕SE.⍙.B '
dispCd←  extLib?  '{0∘⎕SE.Dyalog.Utils.disp}¯1∘↓' ' ⎕SE.⍙.D '
fmtCd←  ' ⎕FMT '

OutStr← { out.buf,← ⍵ }
⍝  Markers for self-doc code. Drawback: the fancy markers are wider than std Dyalog characters. 
mergeMarker← FANCY_MARKERS⊃ '→▶'
aboveMarker← FANCY_MARKERS⊃ '↓▼'

MODE_STD MODE_LIST MODE_TABLE MODE_CODE← 1 0 ¯1 ¯2

ERROR← { rc outBuf∘← ⍵ }
⎕FX 'ch← CUR' 'cur← in.buf[in.cur]'
PEEK_AT← { ⍵≤ ≢in.buf: in.buf[p] ⋄ ¯1}
⎕FX 'ch←PEEK' 'ch← PEEK_AT in.cur+1'
STATE← { oldState state⊢← state ⍵}

OutStr← { out.buf,← ⍵ }
⎕FX 'CodeInit' 'code.(buf cur← '''' 0)' 
⎕FX 'CodeOut' 'out.buf,← code.buf ⋄ CodeInit'


⍝  Preamble code string...
  OutStr '{' 
  :IF useNs 
     OutStr '⍺←⎕NS⍬⋄' 
  :EndIf 

  :Select mode 
    :Case MODE_STD
      OutStr boxAll⊃ mergeCd dispCd  
    :Case MODE_LIST
      OutStr dispCd
    :Case MODE_TABLE:
      OutStr dispCd,'⍪'
    :Case MODE_CODE
      OutStr boxAll⊃ mergeCd dispCd  
      :If useNs
         OutStr '⍺'
      :EndIf 
      OutStr '{'
    :Else 
      ERROR 11 'Unknown mode option in left arg' 
      :return 
  :EndSelect 

   :while in.cur < in.max  
    ⍝  Logic for changing state (NONE, CF_START)
      :If (state == NONE) 
          :If  (CUR!= LBR) 
            STATE(TF) 
            OutCh(QT)
          :Else 
            STATE(CF_START)
            in.cur+← 1   ⍝  Move past the left brace
          :EndIf 
      :EndIf 
      :If (state = CF_START)
            nspaces← 0 
            :If (oldState = TF)   ⍝  Terminate existing TF
                OutStr ''' '  
            :EndIf 
          ⍝  cfStart marks start of code field (in case a self-documenting CF)
            cfStart← in.cur             ⍝  If a space field, this is ignored.
          ⍝  Skip leading blanks in CF/SF code, though NOT in any associated document strings 
            j← in.cur 
            nspaces← 0 
            :while ' '=PEEK_AT j
                j+← 1
                nspaces +← 1
                in.cur+← 1 
            :End 
          ⍝  See if we really have a SF: 0 or more (solely) blanks between matching braces.
            :If j < in.max ⋄ :Andif '}'= PEEK_AT j  ⍝  Is a SF!
                :If ×nspaces   
                      CodeStr '(''⍴⍨',(⍕nspaces),')'
                      CodeOut;
                :Endif 
                STATE (NONE);    ⍝  Set state to NONE: SF is complete !
            :Else                ⍝  It's a CF.
                STATE (CF)
                bracketDepth← 1
                :If (useNs)
                   OutStr '(⍺{'
                :Else 
                   OutStr '({' 
                CodeInit      ⍝  Ready to write code buffer (doesn't change output buffer).
            :Endif 
      :EndIf   
      :If state = TF       ⍝  Text field 
          :If (CUR == escCh)   ⍝  Check for escape chars
            ch← PEEK
            ++in.cur
            :If (ch == escCh)
                OutCh(escCh);
            :Elseif  (ch == LBR || ch == RBR)
                OutCh(ch);
            :Else :If (ch == DMND)
                OutCh(crOut);
            :Else 
                --in.cur; 
                OutCh(CUR);
            :EndIf  
          :Elseif  (CUR == LBR)
            STATE(CF_START);     ⍝  TF will end at (state == CF_START) above.
          :Else 
            OutCh(CUR);
            :if (CUR == QT)       ⍝  Double internal quotes per APL
              OutCh(QT)
            :EndIf  
          :EndIf                 ⍝ :If (CUR == escCh)        
      :EndIf ⍝ state = TF
      :If state == CF         ⍝  Code field 
        :If (CUR == RBR) 
            --bracketDepth;
            :If (bracketDepth > 0) 
               CodeCh(CUR);
            :Else             ⍝  Terminating right brace: Ending Code Field!
              CodeOut;
              OutStr( '}⍵)');
              bracketDepth=0;
              STATE(NONE);
            :EndIf 
        :Elseif  (CUR == LBR) 
          ++bracketDepth;
          CodeCh(CUR);
        :Elseif  (CUR == SQ || CUR == DQ)
          int i;
          int tcur=CUR;
          CodeCh(SQ);
          for (in.cur++; in.cur<in.max; ++in.cur){ 
              :If (CUR == tcur) 
                  :If (PEEK == tcur) 
                      CodeCh(tcur)
                      if (tcur == SQ)
                          CodeCh(tcur);
                      ++in.cur;
                  :Else  
                      break
                  :EndIf 
              :Else
                  tcur← CUR;
                  :If (tcur = escCh)
                      ch← PEEK  
                      :If (ch == DMND) 
                          CodeCh(crOut);
                          ++in.cur;
                      :Elseif  (ch == escCh)
                          CodeCh(escCh);
                          ++in.cur;
                      :Else 
                          CodeCh(escCh)
                      :EndIf 
                  :Else  
                      CodeCh(tcur);
                      if (tcur == SQ)
                          CodeCh(tcur);
                  :EndIf 
              :EndIf 
          :EndWhile  ⍝ for (in.cur++; in.cur<in.max; ++in.cur)
          CodeCh(SQ);
        :Elseif  CUR = OMG_US ⋄ :OrIf (CUR = escCh) ∧ PEEK = '⍵' 
        ⍝  we see ⍹ or `⍵ (where ` is the current escape char)
          in.cur+← CUR=escCh          ⍝  Skip whatever was just matched (`⍵ or ⍹)
          :If isdigit PEEK            ⍝  Is ⍹ or `⍵ followed by digits?
            ++in.cur;                 ⍝  Yes: `⍵NNN or ⍹NNN. 
            tIx← (+/∧\ tBuf∊ ⎕D)↑ tBuf← in.cur↓ in.buf
            omegaNext← ⊃⌽⎕VFI tIx    ⍝  ... and set omegaNext.
            CodeStr '(⍵⊃⍨⎕IO+', tIx, ')'  
          :Else                       ⍝  No: a bare `⍵ or ⍹ 
            tOm← ⍕omegaNext+← 1       ⍝  Increment omegaNext
             CodeStr '(⍵⊃⍨⎕IO+', tOm, ')'  ⍝  Write: '(⍵⊃⍨⎕IO+<omegaNext>)'
          :EndIf 
        :Else 
          :Select CUR 
            :Case '$'  ⍝  Pseudo-builtins $ (⎕FMT) and $$ (Box, i.e. dfns display)
              :If (PEEK!= '$')
                CodeStr(fmtCd)
              :Else {
                CodeStr(boxCd)
                in.cur+← 1 
              :EndIf 
              in.cur+← +/∧\(in.cur↓in.buf)='$'
           :Case '→'   
                :If IfCodeDoc(mergeMarker, mergeCd)
                :Else 
                  CodeCh(CUR);
                :EndIf 
            :Case '↓'
                :If IfCodeDoc(aboveMarker, aboveCd)
                :Else  
                  CodeCh(CUR)
                :EndIf 
            :Case '%' ⍝  Pseudo-builtin % (Over) 
                :If IfCodeDoc(aboveMarker, aboveCd)
                :Else 
                  CodeStr(aboveCd); 
                  in.cur+← +/∧\(in.cur↓in.buf)='%' 
                :EndIf 
            :Else 
                CodeStr CUR   ⍝ Catchall  
          :EndSelect
        :EndIf 
      :EndIf ⍝   if (state == CF)        
      in.cur+← 1
  :EndWhile   ⍝ :While (in.cur...) 

  :If (state == TF)  
      OutCh(QT);
      STATE(NONE);
  :Elseif  (state != NONE) 
      ERROR( 'Code or Space Field was not terminated properly', 11);
  :EndIf 

  ⍝  Postamble Code String
  OutStr( '⍬}');
  ⍝    Mode 0: extra code because we need to input the format string (fString) 
  ⍝            into the resulting function (see ∆F.dyalog).
  if (mode == MODE_CODE){
      OutStr( '⍵,⍨⍥⊆'); 
      OutCh(SQ);
      OutBufSq(in.buf, in.cur);
      OutCh(SQ);    
      OutCh(RBR);
  }:Else {
      OutCh(OMG);
  }

  RETURN(0);  /* 0= all ok */
}