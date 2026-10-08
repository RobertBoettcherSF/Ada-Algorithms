pragma Ada_2022;
package body Sigmoid with SPARK_Mode => On is
   function Evaluate (X : Input) return Probability is
   begin
      -- Integer percentages from a bounded logistic lookup table.
      case X is
         when -4 => return 2;
         when -3 => return 5;
         when -2 => return 12;
         when -1 => return 27;
         when  0 => return 50;
         when  1 => return 73;
         when  2 => return 88;
         when  3 => return 95;
         when  4 => return 98;
      end case;
   end Evaluate;
end Sigmoid;
