∆DICT← {  
  ⍝H
  ⍝H ┌─∆𝗗𝗜𝗖𝗧───────∆𝗗𝗜𝗖𝗧───────∆𝗗𝗜𝗖𝗧──────∆𝗗𝗜𝗖𝗧───────∆𝗗𝗜𝗖𝗧────────∆𝗗𝗜𝗖𝗧─────┐
  ⍝  │                   See HELP INFORMATION BELOW.                      │
  ⍝  │     HELP doc <== comments (above/below) prefixed with '⍝H'         │
  ⍝  └────────────────────────────────────────────────────────────────────┘
  
    ⍺← ⍬  
  ⍝ Create dictionary namespace and move into it to copy in methods and dictionary elements.
    ⍺ ∇ ((⊃⎕RSI).⎕NS⍬).{   

    ⍝ METHODS IN ALPHABETICAL ORDER...

      Cat1∘← {0::⍙E⍬⋄ 1: _← ⍺⍺ Set1 (Get1 ⍺⍺),  ⊂⍵ }  
      Cat∘←  {0::⍙E⍬⋄ ⍺ {⍺ Cat1 ⍵}¨⍵ }
          
    ⍝ Niladic fns here and below...     
      _← ⎕FX'{_}← Clear' '_←⍙H ⎕THIS⊣ K←V←⍬'
      _← ⎕FX'_←   Copy' '_←⎕NS ⎕THIS'
      _← ⎕FX'_←   Default' '_←D' 

      Del∘←  { ⍺← 0 ⋄ nK← ≢K ⋄ ⍺∨ p=⍥≢ fp← p/⍨ nK> p← K⍳ ⍵: _← ⍙H 1⊣ (K V) /⍨← ⊂0@ fp⊣ nK⍴1 ⋄ ⍙E 61 } 
      Del1∘←  Del∘⊂

      Do∘←  {0::⍙E⍬⋄ 1: _← ⍺ Set  (Get  ⍺) ⍺⍺  ⍵ }         ⍝ Do is Atomic. If ⍺⍺ fails, Do will not update ⍺.
    ⍝ DoNA∘← {0::⍙E⍬⋄ 1: _←  V[K⍳⍺]← (⍺ SetC  ⊂D) ⍺⍺  ⍵ }  ⍝ Non-atomic (SetC instantiates missing items). 2%-80% faster than Do.
      Do1∘← {0::⍙E⍬⋄ 1: _← ⍺ Set1 (Get1 ⍺) ⍺⍺  ⍵ }
          
      Get1∘← { (≢K)> p← K⍳ ⊂⍵: p⊃ V ⋄ ⍺← D ⋄ ⍺ }
      Get∘←  {   
        ~0∊ m← (≢K)>p← K⍳ k← ⍵: V[ p ] ⋄ ⍺← ⊂D ⋄ v← (≢k)⍴⍣ (1= ≢⍺)⊢ ⍺   
        v ≠⍥≢ k: ⍙E 5 ⋄ ~1∊ m: v ⋄ V[ m/ p ]@ (⍸m)⊣ v 
      }
      
      HasKeys∘← { K∊⍨ ⍵ } 
      HasKey∘←  HasKeys⊂  

      _← ⎕FX'_← Items' '_← ↓⍉↑K V' 
      _← ⎕FX'_← Keys' '_← K'  
    
    ⍝ Pop: Optimized...
      Pop∘←  { nK←≢K 
        ~0∊ m← nK> p← K⍳ k← ⍵:  ⍙H v⊣ (K V) /⍨← ⊂0@ p⊣ nK⍴ 1 ⊣ v← V[ p ] 
            ⍺← ⊢ ⋄ 0≡⍺0: ⍙E 61 ⋄ v← (≢k)⍴⍣ (1=≢⍺)⊢ ⍺  
        v ≠⍥≢ k: ⍙E 5 ⋄ ~1∊ m: v  ⋄ v← V[ m/ p ]@ (⍸m)⊣ v 
            ⍙H v⊣ (K V) /⍨← ⊂0@ (m/ p)⊣ nK⍴ 1 
      }
      Pop1∘← ⊃ Pop⍥⊂
     
    ⍝ Set/1: 
    ⍝ Stores the value for each key, maintaining existing ordering of existing keys.
    ⍝ ────────────────────────────
    ⍝ vî: input values; mo: mask of "old" keys; mu: mask of unique new keys.
      Set∘←  {    
        0::⍙E⍬⋄ ⍺←⊢ ⋄  k vî← ⍺ ⍵ ⋄  v← (≢k)⍴⍣ (1= ≢vî)⊢ vî                                              
        ~0∊ mo← (≢K)> p← K⍳ k: _← vî⊣ V[ p ]← v ⋄ V[ mo/ p ]← mo/ v            ⍝ V<old>← v<old>
            mu← (~mo)∧≠k ⋄ K,← mu/ k ⋄ V,← mu/ v@ (k⍳⍨,k)⊢ v ⋄ 1: _← ⍙H vî     ⍝ V,← v<new_last}
      }
      Set1∘← { ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ (≢K)> p← K⍳ ⊂k: (p⊃ V)← v ⋄ K,∘⊂← k ⋄ 1: _← ⍙H v ⊣ V,∘⊂← v }
  
    ⍝ SetC/SetC1: "Set Conditionally"
    ⍝ Like Set/1, but only stores a value for the first occurrence of a new key.
    ⍝ See Help Info below.  Like Python method setdefault().
    ⍝ ──────────────────────────── 
    ⍝ mo: mask of "old" keys; mu: mask of unique new keys.
      SetC∘← {   
        0::⍙E⍬⋄ ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ v← (≢k)⍴⍣(1=≢v)⊢v  
        ~0∊ mo← (≢K)> p← K⍳ k: _← V[ p ] ⋄ v← V[ mo/ p ]@ (⍸mo)⊣ v            ⍝ v<old>← V<old>
            mu← (~mo)∧ ≠k ⋄ K,← mu/ k ⋄ V,← mu/ v ⋄ 1: _← ⍙H v[ k⍳⍨,k ]       ⍝ V,←  v<new_first> 
      }
      SetC1∘← { 0::⍙E⍬⋄ ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ (≢K)> p← K⍳ ⊂k: _← (p⊃ V) ⋄ K,∘⊂← k ⋄ 1: _← ⍙H V,∘⊂← v }

      SortBy∘← { 
          ⍺←⎕THIS ⋄ sk← ⍵ K⊃⍨ 0=≢⍵ ⋄ sk ≠⍥≢ K: ⍙E 5
          ⍺.(K V)← K V ⋄ ⍺.(K V)⌷⍨← ⊂⊂⍋sk ⋄ ⍺.(K← 1500⌶K) ⋄ 1: _←  ⍺
      }

      _← ⎕FX'_← Vals' '_←V' 

    ⍝ ⎕THIS.∆DICT: A user- and internally-accessible method, for d.∆DICT 'Help', etc.
      ∆DICT∘← ⍺⍺ 

    ⍝ Runtime Dict-Internal (Non-user) Utilities: ⍙H, ⍙E
    ⍝ ⍙H: Hash Utility: use in methods after K is updated, ensuring K is hashed. 
    ⍝ Passes on ⍵ unchanged.
      ⍙H∘← { ×1(1500⌶)K: ⍵ ⋄ ⍵⊣ K∘← 1500⌶K }     
    ⍝ Error Handling in methods: ⍙E ⍵
    ⍝ Passes on signals (⍵≡ ⍬) or generates them (⍵∊ 11 5 61).
      ⍙E∘←  ⎕SIGNAL/ '∆DICT '{ 
        0=≢⍵: ⎕DMX.((⍺⍺,EM)EN) 
            en← 11 5 61
            em← ⊂ 'DOMAIN ERROR. See ∆DICT ''help''.'   ⍝ 11
            em,←⊂ 'LENGTH ERROR'                        ⍝  5
            em,←⊂ 'KEY ERROR: Key(s) not found'         ⍝ 61
            em,←⊂ 'Unknown error!'                      ⍝ anything else
        ⍵,⍨ ⊂⍺⍺, em⊃⍨ en⍳ ⊂⍵
      }
    
    ⍝ Creation-time Main Fn-internal Utility 
    ⍝ ⍙Help: Help Display in lieu of Dict Creation
      ⍙Help← {0=≢_h←'^\h*⍝H(.*)' ⎕S '\1'⊣⎕NR '∆DICT': ⎕←'Whoops! No help available' ⋄ ⎕ED '_h'} 
   
    ⍝ ┌───────────────────────────────────────────────────────────┐
    ⍝ │                       Executive ;-)                       │
    ⍝ ├───────────────────────────────────────────────────────────┤  
    ⍝ │ [⍺]: D[←⍬];  ⍵: K V or ⍬ or 'Help'                        │
    ⍝ │ Conformability of keys (K) and values (V) handled at Set. │
    ⍝ └───────────────────────────────────────────────────────────┘
      ⎕IO ⎕ML∘← 0 1 ⋄ 'help'≡ ⎕C ⍵: ⍙Help⍬ ⋄ _← ⎕DF ']',⍨ '.[Dictionary',⍨ ⊃⎕NSI
      (D K V)∘← ⍺ ⍬ ⍬ ⋄ ⍬(⍬ ⍬)∊⍨ ⊂⍵: ⎕THIS ⋄ (2≠≢⍵)∨1≠⍴⍴⍵: ⍙E 11 ⋄ ⎕THIS⊣ Set ⍵ 
    } ⍵

  ⍝H ┌────────────────────────────────────────────────────────────────────┐
  ⍝H │  ∆𝗗𝗜𝗖𝗧: 𝗔𝗻 𝗢𝗿𝗱𝗲𝗿𝗲𝗱 𝗗𝗶𝗰𝘁𝗶𝗼𝗻𝗮𝗿𝘆 𝘂𝘁𝗶𝗹𝗶𝘁𝘆                                            │
  ⍝H │   ○ Keys and values may have any shape and type.                   │
  ⍝H │   ○ The keys are hashed for performance (see Hashing).             │
  ⍝H │   ○ The dictionary maintains items in order of creation            │
  ⍝H │     or as sorted (see SortBy).                                     │
  ⍝H │   ○ Novel methods include  op Do/Do1  and  Cat/Cat1 (see below).   │
  ⍝H │      keys← 'NYT' 'TOL' ⋄ news← 0 ∆DICT ⍬                           │
  ⍝H │      keys +news.Do 1        ⍝ ==> keys news.Set 1+ news.Get keys   │
  ⍝H │      'TOL +news.Do1 1       ⍝ ==> keys news.Set 1+ news.Get keys   │
  ⍝H ├────────────────────────────────────────────────────────────────────┤   
  ⍝H │   Function:  ∆DICT                                                 │
  ⍝H │   Load via   ]LOAD ∆DICT                                           │
  ⍝H │      or      ⊢2 ⎕FIX 'file://∆DICT.dyalog'                         │
  ⍝H └────────────────────────────────────────────────────────────────────┘
  ⍝H
  ⍝H ┌─────────────────────────────────────────────────────────────────┐
  ⍝H │   𝐃𝐢𝐜𝐭𝐢𝐨𝐧𝐚𝐫𝐲 𝐂𝐫𝐞𝐚𝐭𝐢𝐨𝐧                                              │
  ⍝H └─────────────────────────────────────────────────────────────────┘
  ⍝H 
  ⍝H [a] d← [default←⍬] ∆DICT kk vv              where vectors of keys and values: kk ≡⍥≢ vv
  ⍝H                                             ('key1' 'key2') ((○1)(○?1000))
  ⍝H                          ↓⍉↑kv1 kv2...      where kvN is an "item" (a key-value pair), 
  ⍝H                                             ('key1' (○1)) ('key2' (○?1000))
  ⍝H [b] d← [default←⍬] ∆DICT ⍬                  generates an empty dictionary (with default value ⍬)
  ⍝H
  ⍝H Returns a dictionary namespace 𝒅 containing a hashed, ordered list of items and a set of service functions.
  ⍝H The default value is set to ⍬. A useful default value for counters is 0.
  ⍝H
  ⍝H [c] [𝒅.]∆DICT 'Help'                        shares this help information (the case of keyword 'Help' is ignored).
  ⍝H
  ⍝H ┌──────────────────────┐
  ⍝H │   𝐃𝐢𝐜𝐭𝐢𝐨𝐧𝐚𝐫𝐲 𝐌𝐞𝐭𝐡𝐨𝐝𝐬   │
  ⍝H └──────────────────────┘
  ⍝H ┌──────────────────────────────   KEY   ────────────────────────────────┐
  ⍝H │   𝒅.𝑴𝒆𝒕𝒉𝒐𝒅: 𝒅 is a dict created via d←∆DICT or d← d0.Copy                   │
  ⍝H │            𝑴𝒆𝒕𝒉𝒐𝒅: see 𝒎𝒆𝒕𝒉𝒐𝒅𝒔 below                                         │
  ⍝H │   𝒌: a (disclosed) key     𝒌𝒌: 1 (enclosed) or more keys                 │
  ⍝H │   𝒗: a (disclosed) value   𝒗𝒗: 1 (enclosed) or more values                │
  ⍝H │                           𝒗𝒗*: If (⊂v), scalar extension applies            │   
  ⍝H │                       𝗱𝗲𝗳𝗮𝘂𝗹𝘁𝘀*: Scalar extension 𝗱𝗼𝗲𝘀 apply                │     
  ⍝H │                       𝗱𝗲𝗳𝗮𝘂𝗹𝘁𝘀†: Scalar extension 𝗱𝗼𝗲𝘀 𝗻𝗼𝘁 apply            │     
  ⍝H │   𝒂:  arbitrary data       𝒂𝒂: any (enclosed) list of arbitrary data      │
  ⍝H │   𝒃:  Boolean value        𝒃𝒃: Boolean values                          │
  ⍝H │                            𝒔𝒔: sortable keys                           │
  ⍝H │   {𝒙𝒙}←   shy return value                                            │
  ⍝H └───────────────────────────────────────────────────────────────────────┘
  ⍝H ┌─────────────────┐
  ⍝H │   𝗕𝗮𝘀𝗶𝗰 𝗠𝗲𝘁𝗵𝗼𝗱𝘀   │
  ⍝H └─────────────────┘                   
  ⍝H    Creating Dictionaries:  newD← [def] [𝒅.]∆DICT kk vv*                  def is the default val (any type or shape).   
  ⍝H                                  [def] [𝒅.]∆DICT ⍬                       def defaults to ⍬.
  ⍝H       [Cloning]            newD←        𝒅.Copy                           copies keys, values, and default.
  ⍝H
  ⍝H    Setting:
  ⍝H       [Items]            {vv}←     𝒅.Set  kk vv*                         See Duplicate Keys
  ⍝H                          {vv}←  kk 𝒅.Set  vv*                             "      "      "
  ⍝H       [Single Item]       {v}←     𝒅.Set1 k  v       
  ⍝H       ["Conditionally": Update New Items only, leaving old items as is]      
  ⍝H                          {vv}←     𝒅.SetC kk vv*                         See Duplicate Keys
  ⍝H                          {vv}←  kk 𝒅.SetC vv*                             "      "      "
  ⍝H ┌───────────────────────────────────────────────  Duplicate Keys ───────────────────────────────────────┐
  ⍝H │  𝗦𝗲𝘁 and 𝗦𝗲𝘁C simulate the logic of 𝗦𝗲𝘁1 and 𝗦𝗲𝘁𝗖¨, while performing much faster (~3-10x).                  │
  ⍝H │  ∘ Each new key is entered in the dictionary from left to right-- existing (old) keys ordering        │
  ⍝H │    is not affected-- regardless of whether repeated in the 𝗦𝗲𝘁 or 𝗦𝗲𝘁𝗖 call.                             │
  ⍝H │  ∘ To have consistent semantics with scalar execution (for 𝗦𝗲𝘁: 𝗦𝗲𝘁1, 𝗦𝗲𝘁¨; for 𝗦𝗲𝘁𝗖: 𝗦𝗲𝘁𝗖1, 𝗦𝗲𝘁𝗖¨):                   │
  ⍝H │    𝗦𝗲𝘁:                                                                                                    │
  ⍝H │      ─ retains the rightmost (most recent) value for each key, old or new;                            │
  ⍝H │      ─ returns the original values passed (L-to-R), consistent with Set1.                             │
  ⍝H │    𝗦𝗲𝘁𝗖:                                                                                                   │
  ⍝H │      ─ for each existing key, retains the existing dictionary value, ignoring any new values;         │
  ⍝H │      ─ for each new key, sets as its value the leftmost value passed in.                                   │
  ⍝H │      ─ returns the existing or newly stored value for each key, existing or new.                      │
  ⍝H │      ─ like 𝗚𝗲𝘁 returns the (now) current values for the keys specified.                                                │
  ⍝H └───────────────────────────────────────────────────────────────────────────────────────────────────────┘
  ⍝H 
  ⍝H    Getting:
  ⍝H       [Values]       vv← [defaults*] 𝒅.Get kk  
  ⍝H       [Single Value]  v←   [default] 𝒅.Get1 k     
  ⍝H                                   * For 𝗚𝗲𝘁, scalar extension is supported for 𝗱𝗲𝗳𝗮𝘂𝗹𝘁𝘀.              
  ⍝H    
  ⍝H    Popping (Getting and then Deleting):                  If 𝐧𝐨 default is explicitly specified...
  ⍝H       [Items]       vv← [defaults*] 𝒅.Pop kk             ... 𝗮𝐧𝗱 if any key in kk not found, an error is signaled.      
  ⍝H       [Single Item]  v←   [default] 𝒅.Pop1 k             ... 𝗮𝐧𝗱 if key k is not found, an error is signaled.
  ⍝H                                  * Like 𝗚𝗲𝘁, 𝗣𝗼𝗽 supports scalar extension for 𝗱𝗲𝗳𝗮𝘂𝗹𝘁𝘀.         
  ⍝H  
  ⍝H    Do Keys Exist?              (Good Option)         (Faster Option)       (Fastest Option)
  ⍝H                                bb← 𝒅.HasKeys kk      bb←   kk∊ 𝒅.Keys      bb←   kk∊ 𝒅.K                          
  ⍝H                                 b← 𝒅.HasKey  k        b← (⊂k)∊ 𝒅.Keys       b← (⊂k)∊ 𝒅.K   
  ⍝H                                                                   
  ⍝H    Sorting Items via Sort Keys (sk):        
  ⍝H                      {newD}← [newD←d] 𝒅.SortBy sk          Resorts the dictionary. Required: sk ≡⍥≢ d.Keys (unless 0=≢sk)
  ⍝H                        ...   [newD←d] 𝒅.SortBy ⍬           If 0=≢sk (⍵), sk is treated as 𝒅.Keys: [newD←d] 𝒅.(SortBy Keys)  
  ⍝H                        ...            𝒅.(SortBy ⎕C Keys)   Sort dict 𝒅 in place by keys, ignoring case.
  ⍝H                       newD←  (𝒅.Copy) 𝒅.(SortBy Vals)      Sort dict 𝒅 in order by values into a new dictionary newD.
  ⍝H            
  ⍝H    Deleting Items:          
  ⍝H       [Items by Key]       {bb}← [bb] 𝒅.Del   kk               If 0∊bb, disallow deleting non-existent keys
  ⍝H       [Single Item by Key] {b}←  [b]  𝒅.Del1  k                If 0=bb, --ditto--
  ⍝H       [All]                {n}←       𝒅.Clear         
  ⍝H                  
  ⍝H    Returning Dictionary Components          
  ⍝H       [Keys]                     kk←  𝒅.Keys (or  𝒅.K)*         * Alter 𝒅.K at your peril. 
  ⍝H       [Vals]                     vv←  𝒅.Vals (or  𝒅.V)*         * Alter 𝒅.V at your peril.
  ⍝H       [Items]                 items←  𝒅.Items                   Alias for 𝒅.(↓⍉↑ Keys Vals)
  ⍝H       [Number of Items]           n← ≢𝒅.Keys  or  ≢𝒅.K
  ⍝H       [Overall default value]   def←  𝒅.Default  or  𝒅.D        Return the current default for missing values.
  ⍝H                                       𝒅.D← newVal               Update the default** for missing values; 
  ⍝H                                                                 the default may be any type or shape.
  ⍝H ┌────────────────────┐                                          ──────────────────
  ⍝H │   𝗔𝗱𝘃𝗮𝗻𝗰𝗲𝗱 𝗠𝗲𝘁𝗵𝗼𝗱𝘀        │                                          ** (default set when the dict. was created).
  ⍝H └────────────────────┘    
  ⍝H    Modifying Values:         
  ⍝H       [Apply <𝗼𝗽 a>]       vv← kk (op 𝒅.Do)  aa                  Performs (vv op aa), where vv are the 
  ⍝H                                                                    values for keys kk.  𝒅.Do is atomic.
  ⍝H                                                                  𝗼𝗽 must be a scalar function supporting vector args.                                                              
  ⍝H                            v←  k  (op 𝒅.Do1) a                   Ditto: v← v op a 
  ⍝H       [Catenate <a>]           vv← kk 𝒅.Cat  aa                  Concat <aa> to value of <kk>: vv← vv,∘⊂¨aa   
  ⍝H                                                                  Equiv: kk d.Set (d.Get kk),∘⊂¨ ⍺⍺   
  ⍝H                                v←  k  𝒅.Cat1 a                   Ditto: v←v,⊂aa
  ⍝H
  ⍝H ┌───────────────┐
  ⍝H │   𝐎𝐭𝐡𝐞𝐫 𝐈𝐧𝐟𝐨    │
  ⍝H └───────────────┘    
  ⍝H Hashing:
  ⍝H ∘ Keys are hashed when a non-empty dictionary is created.
  ⍝H ∘ Keys are rehashed, if needed, after each 𝗦𝗲𝘁 or 𝗦𝗲𝘁1 that includes new keys.
  ⍝H   Rehashing is never necessary when values are altered for existing keys.
  ⍝H ∘ For a dictionary with mixed scalars and non-scalar keys, 
  ⍝H   when the most recently added key is a scalar the dictionary will require rehashing.  
  ⍝H   This is a Dyalog APL 𝙛𝙚𝙖𝙩𝙪𝙧𝙚.
  ⍝H ∘ For a dictionary containing only items of the same storage class:
  ⍝H      - all simple char scalars,                    'a' 'B' '⍴'
  ⍝H      - all simple numeric scalars, or              1 2 3.1J2E24
  ⍝H      - all non-scalar objects                      'ted' (,0J1) (⍳2 2) (,'⍴')
  ⍝H   rehashing will NOT be required when adding one or more objects of that same class. Yay!
  ⍝H ∘ Rehashing occurs when items are deleted or the dictionary is sorted. Duh!
  ⍝H   If 𝗗𝗲𝗹 𝗸𝗸  is used, the rehashing occurs 𝗼𝗻𝗰𝗲, no matter how many keys are in 𝗸𝗸.
  ⍝H   If 𝗗𝗲𝗹1¨𝗸𝗸 is used, then it occurs 𝗼𝗻𝗰𝗲 for each scalar key in 𝗸𝗸 (i.e. for each call to 𝗗𝗲𝗹1)
  ⍝H Help Info (this info):
  ⍝H    [𝒅.]∆DICT 'Help' 
  ⍝H
}