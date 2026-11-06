from mpi4py import MPI
import numpy as np
import time
import sys
import argparse


parser = argparse.ArgumentParser(description="MPI benchmark tool")
allowed_operations = ["allreduce", "bcast", "allgather"]
parser.add_argument(
    "operation",
    nargs="?",
    default="allreduce",
    choices=allowed_operations,
    help=f"Type of MPI operation to run. Allowed values: {', '.join(allowed_operations)} (default: allreduce)"
)
args = parser.parse_args()
operation = args.operation


comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
# Message sizes in bytes
sizes = [2**x for x in range(10, 29)]  # 1KB to roughly 250MB

results = []

for msg_size in sizes:
    # Each float32 element is 4 bytes
    count = msg_size // 4
    # This is an buffer of float32 numbers
    data = np.ones(count, dtype='f4')

    comm.Barrier()  # Sync before timing
    start = MPI.Wtime()

    if operation == "allreduce":
        # You have a buffer of size msg_size
        # Visualize this as an array of "size" (number of processes) blocks
        recv = np.empty_like(data)
        comm.Allreduce(data, recv, op=MPI.SUM)
    elif operation == "bcast":
        if rank == 0:
            comm.Bcast(data, root=0)
        else:
            recv = np.empty_like(data)
            comm.Bcast(recv, root=0)
    elif operation == "allgather":
        recv = np.empty(count * size, dtype='f4')
        # You have a buffer (data) of size msg_size
        # Visualize this as one block in an array of "size" (number of processes) blocks
        comm.Allgather(data, recv)
    else:
        if rank == 0:
            print("Unknown operation")
        exit()

    end = MPI.Wtime()
    duration = end - start

    # Collect and print results
    if rank == 0:
        results.append((msg_size, duration))
        print(f"{operation.upper()} with {size} ranks, {msg_size} bytes: {duration:.6f} s")


# Save results
if rank == 0:
    np.savetxt(f"{operation}_timing_{size}ranks.txt", results, fmt="%d %.6f")
