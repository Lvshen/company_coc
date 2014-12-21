#!/bin/sh

protoc -o login.pb login.proto
protoc -o action.pb action.proto
