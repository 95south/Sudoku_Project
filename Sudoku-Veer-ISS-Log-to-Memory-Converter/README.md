
## Veer ISS Log to Memory Converter  
For Our Computer Architecture Project where we had to run a sudoku solver on Veer Simulator, this python script convertes the veer log file to print the solved sudoko.

#### Usage
**Add the The Following Code to the End of your execution:**
The following code loads the whole suduko board into a temp register so that it can be logged in end of log file.
```
addi t0, zero , 0  
loop:   
    beq t0, SIZE, exit
    add t2, BASE_ADDRESS_OF_BOARD, t0
    lb  t3, 0(t2)
    addi t0,t0,1
    j loop
exit:
```

``lb  t3, 0(t2)`` Make sure to keep this line same and replace SIZE with total SIZE of board and BASE_ADDRESS_OF_BOARD as the base address of the board.

After running this code take the log file and run it with python script. The Output of memoery will be in a csv file
