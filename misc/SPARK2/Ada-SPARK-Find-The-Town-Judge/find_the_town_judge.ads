pragma Ada_2022;
package Find_The_Town_Judge with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Person is Positive range 1 .. Capacity;
   subtype Judge is Integer range 0 .. Capacity;
   type Trust_Matrix is array (Person, Person) of Boolean;

   function Find_Judge (Trust : Trust_Matrix) return Judge with Global => null;
end Find_The_Town_Judge;
