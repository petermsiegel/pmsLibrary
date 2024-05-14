 ∆D_Examples

⍝   Create dictionary
 a←∆D('Italy' 'Naples')('United States' 'Washington, DC')('United Kingdom' 'London')
⍝   Correct one item
 a[⊂'Italy']←⊂'Rome'

⍝   Add two item
 a['France' 'Antarctica']←'Paris' 'Penguins'

⍝   How many?
 'We have',(≢a.Keys),'items'
 We have 5 items

⍝   Display all items
 'Items'
 ↑a.Items
 Items
 Italy Rome
 United States Washington,DC
 United Kingdom London
 France Paris
 Antarctica Penguins

⍝   Remove invalid item 'Antarctica'
 a.Del⊂'Antarctica'
⍝   Sort items back into a
 a←a.(FromIx⍋Keys)
⍝   Display sorted items
 'Sorted items'
 ↑a.Items
 Sorted items
 France Paris
 Italy Rome
 United Kingdom London
 United States Washington,DC
