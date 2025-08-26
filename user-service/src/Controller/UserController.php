<?php
namespace App\Controller;

use Doctrine\DBAL\Connection;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Annotation\Route;
use OpenApi\Attributes as OA;
use Symfony\Contracts\HttpClient\HttpClientInterface;

#[OA\Tag(name: 'Users')]
class UserController
{
    public function __construct(private Connection $db, private HttpClientInterface $httpClient) {}

    #[Route('/users', methods: ['GET'])]
    #[OA\Get(
        path: '/users',
        summary: 'List users',
        tags: ['Users'],
        responses: [
            new OA\Response(
                response: 200,
                description: 'OK',
                content: new OA\JsonContent(
                    type: 'array',
                    items: new OA\Items(
                        type: 'object',
                        properties: [
                            new OA\Property(property: 'id', type: 'integer'),
                            new OA\Property(property: 'name', type: 'string'),
                            new OA\Property(property: 'email', type: 'string')
                        ]
                    )
                )
            )
        ]
    )]
    public function list(): JsonResponse
    {
        $rows = $this->db->fetchAllAssociative('SELECT id, name, email FROM users ORDER BY id DESC');
        return new JsonResponse($rows);
    }

    #[Route('/users/{id}', methods: ['GET'])]
    #[OA\Get(
        path: '/users/{id}',
        summary: 'Get user by id',
        tags: ['Users'],
        parameters: [
            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'integer'))
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'OK',
                content: new OA\JsonContent(
                    type: 'object',
                    properties: [
                        new OA\Property(property: 'id', type: 'integer'),
                        new OA\Property(property: 'name', type: 'string'),
                        new OA\Property(property: 'email', type: 'string')
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: 'Not found',
                content: new OA\JsonContent(
                    type: 'object',
                    properties: [
                        new OA\Property(property: 'code', type: 'integer'),
                        new OA\Property(property: 'message', type: 'string')
                    ]
                )
            )
        ]
    )]
    public function getOne(int $id): JsonResponse
    {
        $row = $this->db->fetchAssociative('SELECT id, name, email FROM users WHERE id = ?', [$id]);
        if (!$row) {
            return new JsonResponse(['message' => 'Not found'], 404);
        }
        return new JsonResponse($row);
    }

    #[Route('/users', methods: ['POST'])]
    #[OA\Post(
        path: '/users',
        summary: 'Create a user',
        tags: ['Users'],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                type: 'object',
                required: ['name','email'],
                properties: [
                    new OA\Property(property: 'name', type: 'string'),
                    new OA\Property(property: 'email', type: 'string', format: 'email')
                ]
            )
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: 'Created',
                content: new OA\JsonContent(
                    type: 'object',
                    properties: [
                        new OA\Property(property: 'id', type: 'integer'),
                        new OA\Property(property: 'name', type: 'string'),
                        new OA\Property(property: 'email', type: 'string')
                    ]
                )
            ),
            new OA\Response(response: 400, description: 'Bad request', content: new OA\JsonContent(type: 'object', properties: [new OA\Property(property: 'code', type: 'integer'), new OA\Property(property: 'message', type: 'string')])),
            new OA\Response(response: 409, description: 'Conflict', content: new OA\JsonContent(type: 'object', properties: [new OA\Property(property: 'code', type: 'integer'), new OA\Property(property: 'message', type: 'string')]))
        ]
    )]
    public function create(Request $request): JsonResponse
    {
        $payload = json_decode($request->getContent(), true) ?? [];
        $name = $payload['name'] ?? null;
        $email = $payload['email'] ?? null;
        if (!$name || !$email) {
            return new JsonResponse(['code' => 400, 'message' => 'name and email are required'], 400);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return new JsonResponse(['code' => 400, 'message' => 'invalid email format'], 400);
        }
        // unique email
        $exists = $this->db->fetchOne('SELECT COUNT(1) FROM users WHERE email = ?', [$email]);
        if ((int)$exists > 0) {
            return new JsonResponse(['code' => 409, 'message' => 'email already exists'], 409);
        }
        $this->db->insert('users', ['name' => $name, 'email' => $email]);
        $id = (int)$this->db->lastInsertId();
        $row = $this->db->fetchAssociative('SELECT id, name, email FROM users WHERE id = ?', [$id]);
        // Fire-and-forget welcome notification (non-blocking for client response)
        try {
            $cid = $request->headers->get('x-correlation-id') ?? bin2hex(random_bytes(8));
            $this->httpClient->request('POST', 'http://notification-service:3000/notifications', [
                'headers' => [
                    'x-correlation-id' => $cid,
                    'Content-Type' => 'application/json',
                ],
                'json' => [
                    'subject' => sprintf('Welcome, %s!', $name),
                    'message' => 'Thanks for joining.',
                    'recipientId' => $id,
                ],
                'timeout' => 2.0,
            ]);
        } catch (\Throwable $e) {
            // Intentionally ignore errors to not block user creation
        }
        return new JsonResponse($row, 201);
    }

    #[Route('/users/{id}', methods: ['PUT'])]
    #[OA\Put(
        path: '/users/{id}',
        summary: 'Update a user',
        tags: ['Users'],
        parameters: [
            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'integer'))
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                type: 'object',
                properties: [
                    new OA\Property(property: 'name', type: 'string'),
                    new OA\Property(property: 'email', type: 'string', format: 'email'),
                ]
            )
        ),
        responses: [
            new OA\Response(response: 200, description: 'OK', content: new OA\JsonContent(type: 'object', properties: [new OA\Property(property: 'id', type: 'integer'), new OA\Property(property: 'name', type: 'string'), new OA\Property(property: 'email', type: 'string')])),
            new OA\Response(response: 400, description: 'Bad request', content: new OA\JsonContent(type: 'object', properties: [new OA\Property(property: 'code', type: 'integer'), new OA\Property(property: 'message', type: 'string')])),
            new OA\Response(response: 404, description: 'Not found', content: new OA\JsonContent(type: 'object', properties: [new OA\Property(property: 'code', type: 'integer'), new OA\Property(property: 'message', type: 'string')])),
            new OA\Response(response: 409, description: 'Conflict', content: new OA\JsonContent(type: 'object', properties: [new OA\Property(property: 'code', type: 'integer'), new OA\Property(property: 'message', type: 'string')]))
        ]
    )]
    public function update(int $id, Request $request): JsonResponse
    {
        $row = $this->db->fetchAssociative('SELECT id FROM users WHERE id = ?', [$id]);
        if (!$row) {
            return new JsonResponse(['code' => 404, 'message' => 'Not found'], 404);
        }
        $payload = json_decode($request->getContent(), true) ?? [];
        $name = $payload['name'] ?? null;
        $email = $payload['email'] ?? null;
        if ($email !== null && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return new JsonResponse(['code' => 400, 'message' => 'invalid email format'], 400);
        }
        if ($email !== null) {
            $exists = $this->db->fetchOne('SELECT COUNT(1) FROM users WHERE email = ? AND id <> ?', [$email, $id]);
            if ((int)$exists > 0) {
                return new JsonResponse(['code' => 409, 'message' => 'email already exists'], 409);
            }
        }
        // Build dynamic update
        $fields = [];
        $values = [];
        if ($name !== null) { $fields[] = 'name = ?'; $values[] = $name; }
        if ($email !== null) { $fields[] = 'email = ?'; $values[] = $email; }
        if ($fields) {
            $values[] = $id;
            $this->db->executeStatement('UPDATE users SET '.implode(', ', $fields).' WHERE id = ?', $values);
        }
        $row = $this->db->fetchAssociative('SELECT id, name, email FROM users WHERE id = ?', [$id]);
        return new JsonResponse($row);
    }

    #[Route('/users/{id}', methods: ['DELETE'])]
    #[OA\Delete(
        path: '/users/{id}',
        summary: 'Delete a user',
        tags: ['Users'],
        parameters: [
            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'integer'))
        ],
        responses: [
            new OA\Response(response: 204, description: 'No Content'),
            new OA\Response(response: 404, description: 'Not found', content: new OA\JsonContent(type: 'object', properties: [new OA\Property(property: 'code', type: 'integer'), new OA\Property(property: 'message', type: 'string')]))
        ]
    )]
    public function delete(int $id): JsonResponse
    {
        $row = $this->db->fetchAssociative('SELECT id FROM users WHERE id = ?', [$id]);
        if (!$row) {
            return new JsonResponse(['code' => 404, 'message' => 'Not found'], 404);
        }
        $this->db->executeStatement('DELETE FROM users WHERE id = ?', [$id]);
        return new JsonResponse(null, 204);
    }

    #[Route('/users/{id}/notify', methods: ['POST'])]
    #[OA\Post(
        path: '/users/{id}/notify',
        summary: 'Send a notification to a user',
        tags: ['Users'],
        parameters: [
            new OA\Parameter(name: 'id', in: 'path', required: true, schema: new OA\Schema(type: 'integer'))
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                type: 'object',
                required: ['subject','message'],
                properties: [
                    new OA\Property(property: 'subject', type: 'string'),
                    new OA\Property(property: 'message', type: 'string')
                ]
            )
        ),
        responses: [
            new OA\Response(response: 201, description: 'Created'),
            new OA\Response(response: 400, description: 'Bad request'),
            new OA\Response(response: 404, description: 'Not found'),
            new OA\Response(response: 503, description: 'Service Unavailable')
        ]
    )]
    public function notify(int $id, Request $request): JsonResponse
    {
        // Ensure recipient exists
        $row = $this->db->fetchAssociative('SELECT id, name FROM users WHERE id = ?', [$id]);
        if (!$row) {
            return new JsonResponse(['code' => 404, 'message' => 'Not found'], 404);
        }
        $payload = json_decode($request->getContent(), true) ?? [];
        $subject = $payload['subject'] ?? null;
        $message = $payload['message'] ?? null;
        if (!$subject || !$message) {
            return new JsonResponse(['code' => 400, 'message' => 'subject and message are required'], 400);
        }
        $cid = $request->headers->get('x-correlation-id') ?? bin2hex(random_bytes(8));
        try {
            // Resolve hostname to IP to avoid any DNS quirk in PHP streams
            $resolved = gethostbyname('notification-service');
            if ($resolved && $resolved !== 'notification-service') {
                $notifUrl = sprintf('http://%s:3000/notifications', $resolved);
            } else {
                $notifUrl = 'http://notification-service:3000/notifications';
            }
            error_log('notify() using URL: '.$notifUrl.' (resolved='.$resolved.')');
            $resp = $this->httpClient->request('POST', $notifUrl, [
                'headers' => [
                    'x-correlation-id' => $cid,
                    'x-origin' => 'user-service',
                    'Content-Type' => 'application/json',
                ],
                'json' => [
                    'subject' => $subject,
                    'message' => $message,
                    'recipientId' => $id,
                ],
                'timeout' => 6.0,
            ]);
            $status = $resp->getStatusCode();
            $data = $resp->toArray(false);
            if ($status === 201) {
                return new JsonResponse($data, 201);
            }
            return new JsonResponse($data, $status);
        } catch (\Throwable $e) {
            // Log exception for debugging
            error_log('notify() error: '.$e->getMessage());
            return new JsonResponse(['code' => 503, 'message' => 'notification-service unavailable'], 503);
        }
    }
 }
