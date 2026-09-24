--  Mersenne_Twister — Ada/SPARK Level 4 educational package for the
--  MT19937 (32-bit) Mersenne Twister of Matsumoto and Nishimura:
--
--      period 2^{19937}−1; state vector of N = 624 Unsigned_32 words;
--      Twist (recurrence with matrix A) then Temper before each extract.
--
--  Create / Init / Reset / Next. Fixed MT_Array (0 .. N−1). Index in
--  0 .. N where Index = N means “need Twist before the next extract”.
--
--  SPARK port of Ada-Mersenne-Twister: hard bounds, no heap, no
--  exceptions — contracts replace auto-seed-on-uninitialised. MT19937-64
--  is omitted so Level 4 proofs stay tractable (N = 624 already dominates
--  the VC load).
--
--  Reference: https://en.wikipedia.org/wiki/Mersenne_Twister

with Interfaces; use Interfaces;

package Mersenne_Twister
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- MT19937 parameters (Matsumoto–Nishimura / Wikipedia)
   ---------------------------------------------------------------------------

   N : constant := 624;
   M : constant := 397;

   Matrix_A   : constant Unsigned_32 := 16#9908B0DF#;
   Upper_Mask : constant Unsigned_32 := 16#80000000#;
   Lower_Mask : constant Unsigned_32 := 16#7FFFFFFF#;
   Temper_B   : constant Unsigned_32 := 16#9D2C5680#;
   Temper_C   : constant Unsigned_32 := 16#EFC60000#;
   Init_F     : constant Unsigned_32 := 1_812_433_253;

   Default_Seed : constant Unsigned_32 := 5489;

   subtype MT_Index is Natural range 0 .. N - 1;
   --  Index = N means the state is exhausted and Twist is required.
   subtype Index_Type is Natural range 0 .. N;

   type MT_Array is array (MT_Index) of Unsigned_32;

   type Generator is private;

   ---------------------------------------------------------------------------
   -- Inspectors
   ---------------------------------------------------------------------------

   function Is_Initialised (G : Generator) return Boolean
     with Global => null;

   function Get_Index (G : Generator) return Index_Type
     with
       Global => null,
       Pre    => Is_Initialised (G);

   function Get_Seed (G : Generator) return Unsigned_32
     with
       Global => null,
       Pre    => Is_Initialised (G);

   function Get_MT (G : Generator; I : MT_Index) return Unsigned_32
     with
       Global => null,
       Pre    => Is_Initialised (G);

   ---------------------------------------------------------------------------
   -- Create / Init / Reset / Next
   ---------------------------------------------------------------------------

   function Create (Seed : Unsigned_32) return Generator
     with
       Global => null,
       Post   => Is_Initialised (Create'Result)
                 and then Get_Index (Create'Result) = N
                 and then Get_Seed (Create'Result) = Seed
                 and then Get_MT (Create'Result, 0) = Seed;

   procedure Init (G : out Generator; Seed : Unsigned_32)
     with
       Global  => null,
       Depends => (G => Seed),
       Post    => Is_Initialised (G)
                  and then Get_Index (G) = N
                  and then Get_Seed (G) = Seed
                  and then Get_MT (G, 0) = Seed;

   procedure Reset (G : in out Generator; Seed : Unsigned_32)
     with
       Global  => null,
       Depends => (G => (G, Seed)),
       Pre     => Is_Initialised (G),
       Post    => Is_Initialised (G)
                  and then Get_Index (G) = N
                  and then Get_Seed (G) = Seed
                  and then Get_MT (G, 0) = Seed;

   --  Extract the next tempered 32-bit word. Twists when Index = N.
   procedure Next (G : in out Generator; Result : out Unsigned_32)
     with
       Global  => null,
       Depends => (G => G, Result => G),
       Pre     => Is_Initialised (G),
       Post    => Is_Initialised (G)
                  and then Get_Seed (G) = Get_Seed (G'Old)
                  and then Get_Index (G) in 1 .. N
                  and then Get_Index (G) =
                    (if Get_Index (G'Old) = N then 1
                     else Get_Index (G'Old) + 1);

   ---------------------------------------------------------------------------
   -- Pure helpers (tempering / twist kernel pieces)
   ---------------------------------------------------------------------------

   function Temper (Y : Unsigned_32) return Unsigned_32
     with Global => null;

private

   type Generator is record
      MT          : MT_Array   := [others => 0];
      Index       : Index_Type := N;
      Seed        : Unsigned_32 := 0;
      Initialised : Boolean    := False;
   end record
     with Type_Invariant =>
       (if Initialised then Index <= N);

   function Is_Initialised (G : Generator) return Boolean is (G.Initialised);

   function Get_Index (G : Generator) return Index_Type is (G.Index);

   function Get_Seed (G : Generator) return Unsigned_32 is (G.Seed);

   function Get_MT (G : Generator; I : MT_Index) return Unsigned_32 is
     (G.MT (I));

end Mersenne_Twister;
