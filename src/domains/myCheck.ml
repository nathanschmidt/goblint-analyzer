open QCheck

let shrink arb = BatOption.default Shrink.nil arb.shrink

module Gen =
struct
  let sequence (gens: 'a Gen.t list): 'a list Gen.t =
    let open Gen in
    let f gen acc = acc >>= (fun xs -> gen >|= (fun x -> x :: xs)) in
    List.fold_right f gens (return [])
end

module Iter =
struct
  let of_gen ~n gen = QCheck.Gen.generate ~n gen |> Iter.of_list

  let of_arbitrary ~n arb = of_gen ~n (gen arb)
end

module Shrink =
struct
  let sequence (shrinks: 'a Shrink.t list) (xs: 'a list) =
    let open QCheck.Iter in
    BatList.combine xs shrinks |>
    BatList.fold_lefti (fun acc i (x, shrink) ->
        let modify_ith y = BatList.modify_at i (fun _ -> y) xs in
        acc <+> (shrink x >|= modify_ith)
      ) empty
end

module Arbitrary =
struct
  let int64: int64 arbitrary = int64 (* S TODO: custom int64 arbitrary with shrinker *)

  let sequence (arbs: 'a arbitrary list): 'a list arbitrary =
    let gens = List.map gen arbs in
    let shrinks = List.map shrink arbs in
    make ~shrink:(Shrink.sequence shrinks) (Gen.sequence gens)

  let varinfo: Cil.varinfo arbitrary = QCheck.always (Cil.makeGlobalVar "arbVar" Cil.voidPtrType) (* S TODO: how to generate this *)
end