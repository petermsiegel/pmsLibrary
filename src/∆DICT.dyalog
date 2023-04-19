∆DICT← {   
  ⍝ Minimalist Ordered dictionary. 
  ⍝  function:  ∆DICT 
  ⍝  Load via   ]LOAD ∆DICT 
  ⍝      or    ⊢ 2 ⎕FIX 'file://∆DICT.dyalog'
  ⍝  See HELP info (⍝H prefix) below.

    ⍙H← {0=≢_h←'^\h*⍝H(.*)' ⎕S '\1'⊣⎕NR '∆DICT': ⎕←'No help available' ⋄ ⎕ED '_h'} 
    ⍙D← ⎕SIGNAL{⊂'EN' 'Message' ,⍥⊂¨11 'See ∆DICT ''help'''} 

    ⍺← ⍬ ⋄ ⎕IO ⎕ML← 0 1 ⋄ 'help'≡⎕C⍵: ⍙H ⍬ ⋄ (⍵≢⍬)∧2>|≡⍵: ⍙D⍬
    ns← (hom← ⊃⎕RSI).⎕NS⍬ ⋄ _← ns.⎕DF (⍕hom),'.[Dictionary]' 
    
    ns.Cat1← {0::⍙E⍬⋄ 1: _← ⍺⍺ Set1 (Get1 ⍺⍺),  ⊂⍵ }  
    ns.Cat←  {0::⍙E⍬⋄ ⍺ {⍺ Cat1 ⍵}¨⍵ }
    
    ns.Del←  { ⍺← 0 ⋄ n← ≢K ⋄ ⍺∨ p=⍥≢ fp← p/⍨ n> p← K⍳ ⍵: _← ⍙H 1⊣ (K V) /⍨← ⊂0@ fp⊣ n⍴1 ⋄ 61⍙E'Key(s) not found' } 
    ns.Del1← ns.Del∘⊂

    ns.Do1←  {0::⍙E⍬⋄ 1: _← ⍺ Set1 (Get1 ⍺)⍺⍺  ⍵ }
    ns.Do←   {0::⍙E⍬⋄ 1: _← ⍺ (⍺⍺ Do1)¨ ⍵ }
    
    ns.Get1← { (≢K)> p← K⍳ ⊂⍵: p⊃ V ⋄ ⍺← D ⋄ ⍺ }
    ns.Get←  { ~0∊ m← (≢K)>p← K⍳ k← ⍵: V[ p ] ⋄ ⍺← ⊂D ⋄ r← ⍺⍴⍨ ≢k ⋄ ~1∊ m: r ⋄ V[ m/ p ]@ (⍸m)⊣ r }
 
    ns.HasKeys← { K∊⍨ ⍵ } 
    ns.HasKey←  ns.HasKeys⊂  

    ns.Set1← { ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ (≢K)> p← K⍳ ⊂k: (p⊃ V)← v ⋄ K,∘⊂← k ⋄ 1: V,∘⊂←  ⍙H v }
    ns.Set←  { 0::⍙E⍬⋄ ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ m← (≢K)> p← K⍳ k 
              ~0∊ m: V[ p ]← v ⋄ V[ m/ p ]← m/ v  
              1: V,← ⍙H (nm/ v)@ (ü⍳ ñ)⊢ 0⍴⍨ ≢K,← ü← ∪ñ← k/⍨ nm← ~m  
    }

  ⍝ SetC: Identical to Set, except sets values only for new keys. (New values for existing keys IGNORED).
    ns.SetC← { 0::⍙E⍬⋄ ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ m← (≢K)> p← K⍳ k 
               ~0∊ m: v← V[ p ] ⋄ (m/ v)← V[ m/ p ]      ⍝ "Inverse" of Set
               1: V,← ⍙H (nm/ v)@ (ü⍳ ñ)⊢ 0⍴⍨ ≢K,← ü← ∪ñ← k/⍨ nm← ~m    
    }
   
    ns.SortBy←   { 
          ⍺←⎕THIS ⋄ sf← ⍵ K⊃⍨ 0=≢⍵ ⋄ K ≢⍥≢ sf: 5⍙E'Length Error; sort keys are of improper length'
          ⍺.(K V)← K V ⋄ ⍺.(K V)⌷⍨← ⊂⊂⍋sf ⋄ ⍺.(K← 1500⌶K) ⋄ 1: _←  ⍺
    }

  ⍝ Internal Hash utility- used AFTER K is updated.
    ns.⍙H← { ×1(1500⌶)K: ⍵ ⋄ ⍵⊣ K∘← 1500⌶K }    ⍝  Passes thru any args 
  ⍝ Internal Error handling
    ns.⍙E← ⎕SIGNAL/ ('∆DICT: '{0=≢⍵:⎕DMX.((⍺⍺,EM)EN)⋄⍺←11⋄(⍺⍺,⍵)⍺ })
  
  ⍝ Niladic User Methods
  ⍝   Not shy: Keys, Vals, Default, Copy
    _Keys←  '_← Keys' '_←K'
    _Vals←  '_← Vals' '_←V'
    _Def←   '_← Default' '_←D'
    _Copy←  '_← Copy' '_←⎕NS ⎕THIS'
  ⍝   Shy: Clear
    _Clear← '{_}← Clear' '_←⍙H ⎕THIS⊣ K←V←⍬'
    _← ns.⎕FX¨ _Keys _Vals _Def _Copy _Clear  

    ns.(D K V)←⍺ ⍬ ⍬  ⋄ 0=≢⍵: ns ⋄ ns⊣ ns.Set ⍵

  ⍝H────────────────────────────────────────────────────────────────────────────────────
  ⍝H ┌─────────────────────────────────────────────────────────────────┐
  ⍝H │               ∆𝗗𝗜𝗖𝗧: 𝗔𝗻 𝗢𝗿𝗱𝗲𝗿𝗲𝗱 𝗗𝗶𝗰𝘁𝗶𝗼𝗻𝗮𝗿𝘆 𝘂𝘁𝗶𝗹𝗶𝘁𝘆                     │
  ⍝H │         Keys and values may have any shape and type.            │
  ⍝H │         The keys are hashed for performance (see Hashing).      │
  ⍝H │         The dictionary maintains items in order of creation.*   │
  ⍝H ├─────────────────────────────────────────────────────────────────┤
  ⍝H │ * Or as sorted (see SortBy).                                    │
  ⍝H └─────────────────────────────────────────────────────────────────┘
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
  ⍝H [c] ∆DICT 'Help'                            shares this help information
  ⍝H
  ⍝H ┌──────────────────────┐
  ⍝H │   𝐃𝐢𝐜𝐭𝐢𝐨𝐧𝐚𝐫𝐲 𝐌𝐞𝐭𝐡𝐨𝐝𝐬   │
  ⍝H └──────────────────────┘
  ⍝H ┌──────────────────────────────   KEY   ────────────────────────────────┐
  ⍝H │   𝒅.𝑴𝒆𝒕𝒉𝒐𝒅: 𝒅 is a dict created via d←∆DICT or d← d0.Copy             │
  ⍝H │            𝑴𝒆𝒕𝒉𝒐𝒅: see 𝒎𝒆𝒕𝒉𝒐𝒅𝒔 below                                   │
  ⍝H │   𝒌: a (disclosed) key     𝒌𝒌: 1 (enclosed) or more keys              │
  ⍝H │   𝒗: a (disclosed) value   𝒗𝒗: 1 (enclosed) or more values             │
  ⍝H │                            𝒗𝒗*: If (⊂v), scalar extension applies     │          
  ⍝H │   𝒂:  arbitrary data       𝒂𝒂: any (enclosed) list of arbitrary data  │
  ⍝H │   𝒃:  Boolean value        𝒃𝒃: Boolean values                         │
  ⍝H │                            𝒔𝒔: sortable keys                           │
  ⍝H │   𝒏:  a non-neg integer                                               │
  ⍝H │   {𝒙𝒙}←   shy return value                                            │
  ⍝H └───────────────────────────────────────────────────────────────────────┘
  ⍝H ┌─────────────────┐
  ⍝H │   𝗕𝗮𝘀𝗶𝗰 𝗠𝗲𝘁𝗵𝗼𝗱𝘀   │
  ⍝H └─────────────────┘                   
  ⍝H    Creating Dictionaries:  newD← [v] [𝒅.]∆DICT kk vv                  
  ⍝H                                  [v] [𝒅.]∆DICT ⍬                      
  ⍝H       [Cloning]            newD←      𝒅.Copy
  ⍝H
  ⍝H    Setting and Getting: 
  ⍝H       [Items]            {vv}←     𝒅.Set  kk vv*     vv← [defaults] 𝒅.Get kk  
  ⍝H                          {vv}←  kk 𝒅.Set  vv* 
  ⍝H       [Single Item]       {v}←     𝒅.Set1 k  v        v←  [default] 𝒅.Get1 k    
  ⍝H       [Update New Items only, leaving old items as is]      
  ⍝H                          {vv}←     𝒅.SetC kk vv*               
  ⍝H                          {vv}←  kk 𝒅.SetC vv*                    
  ⍝H  
  ⍝H    Validating Items               (Good Option)      (Faster Option)      (Fastest Option)
  ⍝H                                bb← 𝒅.HasKeys kk      bb←   kk∊ 𝒅.Keys      bb←   kk∊ 𝒅.K                          
  ⍝H                                 b← 𝒅.HasKey k         b← (⊂k)∊ 𝒅.Keys       b← (⊂k)∊ 𝒅.K   
  ⍝H                                                                   
  ⍝H    Sorting Items:        
  ⍝H                      {newD}← [newD←d] 𝒅.SortBy ss  
  ⍝H            
  ⍝H    Deleting Items:          
  ⍝H       [Items by Key]       {bb}← [bb] 𝒅.Del   kk                 If 0∊bb, disallow deleting non-existent keys
  ⍝H       [Single Item by Key] {b}←  [b]  𝒅.Del1  k                  If 0=bb, --ditto--
  ⍝H       [All]                {n}←       𝒅.Clear         
  ⍝H                  
  ⍝H    Returning Dictionary Components          
  ⍝H       [Keys]                     kk←  𝒅.Keys                             
  ⍝H       [Vals]                     vv←  𝒅.Vals   
  ⍝H       [Items]                 items←  𝒅.(↓⍉↑ Keys Vals)                                                  
  ⍝H       [Number of Items]           n← ≢𝒅.Keys  
  ⍝H       [Overall default value]   def←  𝒅.Default                 Return the current default for missing values
  ⍝H
  ⍝H ┌────────────────────┐
  ⍝H │   𝗔𝗱𝘃𝗮𝗻𝗰𝗲𝗱 𝗠𝗲𝘁𝗵𝗼𝗱𝘀     │
  ⍝H └────────────────────┘    
  ⍝H    Modifying Values:         
  ⍝H       [Apply <op a>]       vv← kk (op 𝒅.Do  ) aa                 Perform (op aa) on value of <kk>: vv← vv op¨ aa
  ⍝H                            v←  k  (op 𝒅.Do1)  a                  Ditto: v← v op a 
  ⍝H       [Catenate <a>]           vv← kk 𝒅.Cat  aa                  Concat <aa> to value of <kk>: vv← vv,∘⊂¨aa      
  ⍝H                                v←  k  𝒅.Cat1 a                   Ditto: v←v,⊂aa
  ⍝H
  ⍝H ┌───────────────┐
  ⍝H │   𝐎𝐭𝐡𝐞𝐫 𝐈𝐧𝐟𝐨    │
  ⍝H └───────────────┘    
  ⍝H Hashing:
  ⍝H ∘ Keys are hashed when a dictionary is created.
  ⍝H ∘ Keys are rehashed, if needed, after each Set, Set1. This is necessary only when
  ⍝H   new keys are added. Rehashing is never necessary when values are altered for existing keys.
  ⍝H ∘ For a dictionary with mixed scalars and non-scalar keys, when the most recently added key is a scalar
  ⍝H   the dictionary will require rehashing.
  ⍝H ∘ For a dictionary with one of: 
  ⍝H       simple char scalars, simple numeric scalars, or non-scalar keys,
  ⍝H   rehashing will NOT be required if an object of the same type is added. This is a "feature" of Dyalog APL.
  ⍝H Help Info:
  ⍝H    ∆DICT 'Help' 
  ⍝H
}