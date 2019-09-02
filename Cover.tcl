## (c) Krishna Subramanian <https://github.com/mongrelgem>
## UART Project <https://github.com/mongrelgem/USART-RTL-Physical-Design>
## Report Bugs and Issues <https://github.com/mongrelgem/USART-RTL-Physical-Design/issues>

#######################

proc pin_cover {} {
set terms [dbGet top.terms]
foreach term $terms {
set pin [dbGet $term.pins.allShapes.shapes.rect]
set name [dbGet $term.name]
set side [dbGet $term.side]
set layer [dbGet $term.layer.name]
puts $name
puts $pin
puts $side
puts $layer
add_shape -net $name -layer $layer -rect $pin
}
uiSetTool selectTool;
} 

pin_cover
puts "#############################################################"
puts "Done!"
#######################
