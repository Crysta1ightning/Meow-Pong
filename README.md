# Meow Pong
This is a pong game created using system verilog.

The important files are in sources folder.

Take the files in the sources folder and the constraint file from the constraint folder and run it.

After getting the bit file, put it into your FPGA and connect it to a VGA screen to play.

### The final output will look like this
![image](https://user-images.githubusercontent.com/49239376/212553888-3874e057-f300-42fd-bf6e-e401774199db.png)
![image](https://user-images.githubusercontent.com/49239376/212553878-db4384af-e6f0-4ff6-9692-00647eef2345.png)

### The rules of playing are
1. 桿子可以上下左右移動，但不能越過中線 (You can move the paddle up down left right, but you may not cross the mid line)
2. 將貓咪打進對面球門得1分 (Push the cat to the opponent's goal to score)
3. 先得7分者勝 (First one to score 7 wins)
4. 右邊是玩家，左邊是電腦 (Player is right side, left side is an computer player)
5. 有兩隻貓咪 (There are two cats)
6. 用BTNC來reset (Use BTNC to reset)
7. 用BTNU, BTNR, BTND, BTNL來控制桿子位置 (Use BTNU, BTNR, BTND, BTNL to control the paddle)
8. 用SW0來凍結畫面 (Use SW0 to freeze the screen)
9. 用SW1使用黑洞技能 (Use SW1 to use the black hole skill)



