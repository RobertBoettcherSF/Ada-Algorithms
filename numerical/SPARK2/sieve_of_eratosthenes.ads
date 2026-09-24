pragma Ada_2022;
package Sieve_Of_Eratosthenes with SPARK_Mode => On is
   Capacity : constant := 20;
   subtype Number is Positive range 1 .. Capacity;
   type Flags is array (Number) of Boolean;

   function Is_Prime (N : Number) return Boolean;
   procedure Sieve (Result : out Flags);
end Sieve_Of_Eratosthenes;
