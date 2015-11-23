module DragonCaptureTB;

reg Clock = 0;
wire [1:0] LED;
always #5 Clock = !Clock;

DragonCapture CaptureDevice(
    .InternalClock(Clock),
    .LED(LED));

initial $monitor("T: %t, [%h, %h]", $time, LED[0], LED[1]);

endmodule
