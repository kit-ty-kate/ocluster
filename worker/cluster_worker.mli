type job_spec = [
  | `Docker of [ `Contents of string | `Path of string ] * Cluster_api.Docker.Spec.options
  | `Obuilder of [ `Contents of string ]
  | `Custom of Cluster_api.Custom.recv
]

module Obuilder_config : sig
  type t

  val v : Obuilder.Sandbox.config -> [ `Btrfs of string | `Rsync of string | `Zfs of string ] -> t
end

type build = 
  switch:Lwt_switch.t ->
  log:Log_data.t ->
  src:string ->
  secrets:(string * string) list ->
  job_spec ->
  (string, [`Cancelled | `Msg of string]) Lwt_result.t

val default_build : ?obuilder:Obuilder_build.t -> build
(** The default build that is used if no [build] argument is given to {! run}. *)

val run :
  ?switch:Lwt_switch.t ->
  ?build:build ->
  ?allow_push:string list ->
  ?prune_threshold:float ->
  ?obuilder:Obuilder_config.t ->
  update:(unit -> (unit -> unit Lwt.t) Lwt.t) ->
  capacity:int ->
  name:string ->
  state_dir:string ->
  Cluster_api.Raw.Client.Registration.t Capnp_rpc_lwt.Sturdy_ref.t ->
  unit Lwt.t
(** [run ~capacity ~name ~state_dir registry] runs a builder that connects to registry and runs up to [capacity] jobs at once.
    The builder registers using the unique ID [name].
    @param switch Turning this off causes the builder to exit (for unit-tests)
    @param build Used to override the default build action (for unit-tests or custom job specifications)
    @param allow_push Docker repositories to which results can be pushed
    @param update Function to run on "selfUpdate" requests. It should do any preparation (such as downloading new images),
                  then return a function to do the actual update. This is so that the first part can run while the node
                  finishes its remaining jobs. The second part is called once all jobs are finished.
                  If the second function returns, the process will exit.
    @param state_dir A persistent directory for Git caches, etc.
    @param prune_threshold Stop and run "docker system prune -af" if free-space is less than this percentage (0 to 100). *)

module Process = Process
module Log_data = Log_data
