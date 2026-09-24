-- Main Application Entry Point 
with Ada.Text_IO; use Ada.Text_IO;
with Sieve_Of_Sundaram; use Sieve_Of_Sundaram;

procedure Main is
   Limit  : constant Integer := 50;
   Primes : constant Prime_Array := Standard_Sundaram (Limit);
begin
   Put_Line ("--- Sieve of Sundaram Implementation ---");
   Put_Line ("Generated primes up to " & Integer'Image(Limit) & ":");
   
   for I in Primes'Range loop
      Put (Integer'Image(Primes(I)) & " ");
   end loop;
   New_Line;
   
   Put_Line ("Total prime count up to 50: " & 
             Integer'Image(Count_Primes_Sundaram(50)));
end Main;
