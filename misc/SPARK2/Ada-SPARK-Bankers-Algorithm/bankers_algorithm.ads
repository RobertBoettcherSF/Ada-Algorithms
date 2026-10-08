pragma SPARK_Mode (On);
package Bankers_Algorithm is
   Max_Processes : constant := 4;
   Max_Resources : constant := 3;
   subtype Process_Id is Positive range 1 .. Max_Processes;
   subtype Resource_Id is Positive range 1 .. Max_Resources;
   subtype Amount is Natural range 0 .. 20;
   subtype Work_Amount is Natural range 0 .. 100;
   type Vector is array (Resource_Id) of Amount;
   type Work_Vector is array (Resource_Id) of Work_Amount;
   type Matrix is array (Process_Id, Resource_Id) of Amount;
   type State is record
      Available  : Vector;
      Allocation : Matrix;
      Maximum    : Matrix;
   end record;
   function Need (S : State; P : Process_Id; R : Resource_Id) return Amount
     with Post => (if S.Maximum (P, R) >= S.Allocation (P, R) then
                     Need'Result = S.Maximum (P, R) - S.Allocation (P, R)
                   else Need'Result = 0);
   function Is_Safe (S : State) return Boolean;
   procedure Request
     (S : in out State; P : Process_Id; R : Resource_Id; N : Amount; Granted : out Boolean)
     with Pre => S.Maximum (P, R) >= S.Allocation (P, R),
          Post => (if Granted then S.Allocation (P, R) = S'Old.Allocation (P, R) + N
                  and S.Available (R) = S'Old.Available (R) - N);
end Bankers_Algorithm;
