--  Acorn_Generator — Ada/SPARK Level 4 educational package for the
--  Additive Congruential Random Number (ACORN) generator of order k:
--
--      for i in 1 .. k:
--          Y_i ← (Y_i + Y_{i-1}) mod M
--
--  Output variate is Y_k. State vector Y[0 .. k]; Y_0 is held fixed.
--  Create / Reset from a length-(k+1) seed prefix or a single seed
--  expanded via an LCG fill (odd Y_0 forced when M is even).
--
--  SPARK port of Ada-ACORN-Generator: hard bounds, no heap, no
--  exceptions, no Long_Float — contracts replace Invalid_Argument.
--  Modulus is capped at 2**32 so modular add / LCG stay inside a
--  single mod-2**64 word without wrap.
--
--  Reference: https://en.wikipedia.org/wiki/ACORN_(PRNG)

package Acorn_Generator
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Word type and order / modulus bounds
   ---------------------------------------------------------------------------

   type Value is mod 2 ** 64;

   Max_Order : constant Positive := 64;
   subtype Order_Type is Positive range 1 .. Max_Order;

   --  Cap at 2**32 so (M-1)+(M-1) and LCG_A*State+LCG_C fit in Value
   --  without modular wrap, keeping Add_Mod / LCG proveable at Level 4.
   Max_Modulus     : constant Value := 2 ** 32;
   Default_Modulus : constant Value := Max_Modulus;
   subtype Modulus_Type is Value range 2 .. Max_Modulus;

   ---------------------------------------------------------------------------
   -- Seed / state arrays (fixed buffer; used prefix is 0 .. Order)
   ---------------------------------------------------------------------------

   type State_Array is array (Natural range 0 .. Max_Order) of Value;

   type Generator is private;

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Order (K : Positive) return Boolean
     with
       Global => null,
       Post   => Is_Valid_Order'Result = (K <= Max_Order);

   function Is_Valid_Modulus (M : Value) return Boolean
     with
       Global => null,
       Post   => Is_Valid_Modulus'Result = (M in Modulus_Type);

   function Seeds_In_Range
     (Order : Order_Type;
      M     : Modulus_Type;
      Seeds : State_Array) return Boolean
     with
       Global => null,
       Post   => Seeds_In_Range'Result =
         (for all I in 0 .. Natural (Order) => Seeds (I) < M);

   function Is_Initialised (G : Generator) return Boolean
     with Global => null;

   function Order_Of (G : Generator) return Order_Type
     with
       Global => null,
       Pre    => Is_Initialised (G);

   function Modulus_Of (G : Generator) return Modulus_Type
     with
       Global => null,
       Pre    => Is_Initialised (G);

   function Get_Y (G : Generator; Index : Natural) return Value
     with
       Global => null,
       Pre    => Is_Initialised (G) and then Index <= Natural (Order_Of (G)),
       Post   => Get_Y'Result < Modulus_Of (G);

   ---------------------------------------------------------------------------
   -- Create / Reset / Next
   ---------------------------------------------------------------------------

   function Create
     (Order : Order_Type;
      M     : Modulus_Type;
      Seeds : State_Array) return Generator
     with
       Global => null,
       Pre    => Seeds_In_Range (Order, M, Seeds),
       Post   => Is_Initialised (Create'Result)
                 and then Order_Of (Create'Result) = Order
                 and then Modulus_Of (Create'Result) = M
                 and then
                   (for all I in 0 .. Natural (Order) =>
                      Get_Y (Create'Result, I) = Seeds (I));

   function Create
     (Order : Order_Type;
      M     : Modulus_Type;
      Seed  : Value) return Generator
     with
       Global => null,
       Pre    => Seed < M,
       Post   => Is_Initialised (Create'Result)
                 and then Order_Of (Create'Result) = Order
                 and then Modulus_Of (Create'Result) = M
                 and then
                   (for all I in 0 .. Natural (Order) =>
                      Get_Y (Create'Result, I) < M);

   procedure Reset (G : in out Generator; Seeds : State_Array)
     with
       Global  => null,
       Depends => (G => (G, Seeds)),
       Pre     => Is_Initialised (G)
                  and then Seeds_In_Range (Order_Of (G), Modulus_Of (G), Seeds),
       Post    => Is_Initialised (G)
                  and then Order_Of (G) = Order_Of (G'Old)
                  and then Modulus_Of (G) = Modulus_Of (G'Old)
                  and then
                    (for all I in 0 .. Natural (Order_Of (G)) =>
                       Get_Y (G, I) = Seeds (I));

   procedure Reset (G : in out Generator; Seed : Value)
     with
       Global  => null,
       Depends => (G => (G, Seed)),
       Pre     => Is_Initialised (G) and then Seed < Modulus_Of (G),
       Post    => Is_Initialised (G)
                  and then Order_Of (G) = Order_Of (G'Old)
                  and then Modulus_Of (G) = Modulus_Of (G'Old)
                  and then
                    (for all I in 0 .. Natural (Order_Of (G)) =>
                       Get_Y (G, I) < Modulus_Of (G));

   procedure Next (G : in out Generator; Result : out Value)
     with
       Global  => null,
       Depends => (G => G, Result => G),
       Pre     => Is_Initialised (G),
       Post    => Is_Initialised (G)
                  and then Order_Of (G) = Order_Of (G'Old)
                  and then Modulus_Of (G) = Modulus_Of (G'Old)
                  and then Result < Modulus_Of (G)
                  and then Result = Get_Y (G, Natural (Order_Of (G)))
                  and then Get_Y (G, 0) = Get_Y (G'Old, 0);

   procedure Copy_State (G : Generator; Buf : out State_Array)
     with
       Global  => null,
       Depends => (Buf => G),
       Pre     => Is_Initialised (G),
       Post    => (for all I in 0 .. Natural (Order_Of (G)) =>
                     Buf (I) = Get_Y (G, I));

   function Add_Mod (X, Y : Value; M : Modulus_Type) return Value
     with
       Global => null,
       Pre    => X < M and then Y < M,
       Post   => Add_Mod'Result < M
                 and then Add_Mod'Result =
                   (if X + Y >= M then X + Y - M else X + Y);

private

   type Generator is record
      Order       : Natural      := 0;
      M           : Value        := 0;
      Y           : State_Array  := [others => 0];
      Initialised : Boolean      := False;
   end record
     with Type_Invariant =>
       (if Initialised then
          Order in Order_Type
          and then M in Modulus_Type
          and then (for all I in 0 .. Order => Y (I) < M));

   function Is_Initialised (G : Generator) return Boolean is (G.Initialised);

   function Order_Of (G : Generator) return Order_Type is
     (Order_Type (G.Order));

   function Modulus_Of (G : Generator) return Modulus_Type is
     (Modulus_Type (G.M));

   function Get_Y (G : Generator; Index : Natural) return Value is
     (G.Y (Index));

end Acorn_Generator;
