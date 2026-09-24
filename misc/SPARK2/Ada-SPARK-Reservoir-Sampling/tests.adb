pragma Ada_2022;
with Reservoir_Sampling;
procedure Tests is
   use Reservoir_Sampling;
   Input : constant Stream := [10, 20, 30, 40, 50, 60];
   Choice : constant Choices := [1, 2, 3, 1, 2, 3];
   Result : Reservoir;
begin
   Sample (Input, Choice, Result);
   pragma Assert (Result = [40, 50, 60]);
end Tests;
