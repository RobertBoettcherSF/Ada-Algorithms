-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Median_Filter; use Median_Filter;

procedure Tests is
-- Helper to print result
procedure Report(Name : String; Success : Boolean) is
begin
if Success then Put_Line(Name & " ... PASS"); else Put_Line(Name & " ... FAIL"); end if;
end Report;

begin
Put_Line("--- Starting Verification Suite ---");

-- TEST 1 - 1D Edge Case: Empty Input
declare
Empty_Input : Data_1D(1..0);
Res : Data_1D(1..0);
begin
Res := Process_1D(Empty_Input, 3);
Report("TEST 1 - 1D Empty Input", True);
exception
when others => Report("TEST 1 - 1D Empty Input", False);
end;

-- TEST 2 - 1D Single Element
declare
Inp : Data_1D := (1 => 10);
Res : Data_1D := Process_1D(Inp, 3);
begin
Assert(Res(1) = 10, "Should return original value");
Report("TEST 2 - 1D Single Element", True);
end;

-- TEST 3 - 1D Noise Removal (Impulse Noise)
declare
Inp : Data_1D := (10, 10, 100, 10, 10);
Res : Data_1D := Process_1D(Inp, 3);
begin
Assert(Res(3) = 10, "Median should filter out 100");
Report("TEST 3 - 1D Noise Removal", True);
end;

-- TEST 4 - 1D All Same Values
declare
Inp : Data_1D := (5, 5, 5);
Res : Data_1D := Process_1D(Inp, 3);
begin
Assert(Res(2) = 5, "Should preserve signal");
Report("TEST 4 - 1D Uniform Data", True);
end;

-- TEST 5 - 1D Invalid Kernel (Even Size)
begin
declare
Inp : Data_1D := (1, 2, 3);
Res : Data_1D := Process_1D(Inp, 2);
begin
Assert(False, "Should have raised exception");
end;
exception
when Invalid_Kernel_Size => Report("TEST 5 - 1D Invalid Kernel Size", True);
end;

-- TEST 6 - 2D Uniform Image
declare
Img : Data_2D(1..3, 1..3) := ((1,1,1), (1,1,1), (1,1,1));
Res : Data_2D := Process_2D(Img, 3);
begin
Assert(Res(2,2) = 1, "Median of 1s should be 1");
Report("TEST 6 - 2D Uniform Image", True);
end;

-- TEST 7 - 2D Impulse Noise Removal
declare
Img : Data_2D(1..3, 1..3) := ((10,10,10), (10,100,10), (10,10,10));
Res : Data_2D := Process_2D(Img, 3);
begin
Assert(Res(2,2) = 10, "Median should remove center noise");
Report("TEST 7 - 2D Impulse Noise", True);
end;

-- TEST 8 - 2D Edge Replication
declare
Img : Data_2D(1..2, 1..2) := ((10, 10), (10, 50));
Res : Data_2D := Process_2D(Img, 3);
begin
Assert(Res(2,2) = 10, "Edge replication test");
Report("TEST 8 - 2D Edge Replication", True);
end;

-- TEST 9 - 2D Invalid Kernel Size
begin
declare
Img : Data_2D(1..3, 1..3) := ((1,1,1), (1,1,1), (1,1,1));
Res : Data_2D := Process_2D(Img, 2);
begin
Assert(False, "Should have raised exception");
end;
exception
when Invalid_Kernel_Size => Report("TEST 9 - 2D Invalid Kernel Size", True);
end;

-- TEST 10 - Robustness: Large Image (Minimal Load)
declare
Img : Data_2D(1..10, 1..10) := (others => (others => 5));
Res : Data_2D := Process_2D(Img, 3);
begin
Report("TEST 10 - 2D Performance/Load", True);
end;

-- TEST 11 - 1D Boundaries
declare
Inp : Data_1D := (1, 100, 2);
Res : Data_1D := Process_1D(Inp, 3);
begin
Assert(Res(1) = 1, "Boundary index 1 check");
Report("TEST 11 - 1D Boundary Logic", True);
end;

-- TEST 12 - 2D Minimal (1x1) Image
declare
Img : Data_2D(1..1, 1..1) := (1 => (1 => 5));
Res : Data_2D := Process_2D(Img, 3);
begin
Assert(Res(1,1) = 5, "1x1 Image identity check");
Report("TEST 12 - 2D 1x1 Image", True);
end;

-- TEST 13 - 1D Large Kernel Handling
declare
Inp : Data_1D := (1, 2, 3, 4, 5);
Res : Data_1D := Process_1D(Inp, 5);
begin
Assert(Res(3) = 3, "Large kernel check");
Report("TEST 13 - 1D Large Kernel", True);
end;

Put_Line("--- All Tests Completed ---");
end Tests;
