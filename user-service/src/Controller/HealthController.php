<?php
namespace App\Controller;

use Doctrine\DBAL\Connection;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Annotation\Route;

class HealthController
{
    public function __construct(private Connection $db) {}

    #[Route('/health', methods: ['GET'])]
    public function health(): JsonResponse
    {
        return new JsonResponse(['status' => 'ok']);
    }

    #[Route('/ready', methods: ['GET'])]
    public function ready(): JsonResponse
    {
        try {
            $this->db->executeQuery('SELECT 1');
            return new JsonResponse(['status' => 'ready']);
        } catch (\Throwable $e) {
            return new JsonResponse(['status' => 'not_ready', 'error' => $e->getMessage()], 503);
        }
    }
}
